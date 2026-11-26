# Rebuild the six-scene Antonio Luna short from the checked-in illustrations and voice clips.
# No network, synthesis, image generation or player-progress writes are needed.
[CmdletBinding()]
param(
    [string]$FFmpegPath = 'ffmpeg',
    [string]$WorkDirectory = (Join-Path $env:TEMP 'historyroll-luna-production/render')
)
$ErrorActionPreference = 'Stop'
$culture = [System.Globalization.CultureInfo]::InvariantCulture
$utf8 = New-Object System.Text.UTF8Encoding($false)
$projectRoot = Split-Path $PSScriptRoot -Parent
$dataPath = Join-Path $projectRoot 'docs/story_videos/antonio_luna/antonio_luna_scenes.json'
$data = Get-Content -LiteralPath $dataPath -Raw -Encoding UTF8 | ConvertFrom-Json
if ($data.scenes.Count -ne 6 -or $data.format.total_duration_seconds -lt 60 -or $data.format.total_duration_seconds -gt 90) {
    throw 'Expected exactly six scenes and a 60-90 second timeline.'
}
function Number([double]$value) { return $value.ToString('0.######', $culture) }
function ResourcePath([string]$path) {
    if (-not $path.StartsWith('res://')) { throw "Expected project resource path: $path" }
    return Join-Path $projectRoot $path.Substring(6)
}
function AssTime([double]$value) {
    $cs = [int][Math]::Round($value * 100)
    return '{0}:{1:00}:{2:00}.{3:00}' -f [int][Math]::Floor($cs / 360000), ([int][Math]::Floor($cs / 6000) % 60), ([int][Math]::Floor($cs / 100) % 60), ($cs % 100)
}
function RunFFmpeg([string[]]$Arguments, [string]$Label) {
    Write-Output $Label
    # Windows PowerShell wraps native stderr (including normal FFmpeg diagnostics)
    # as error records. Judge the encoder by its exit code, then restore policy.
    $previousErrorAction = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        & $FFmpegPath @Arguments 2>&1 | Out-File -LiteralPath $logPath -Append -Encoding UTF8
        $encoderExit = $LASTEXITCODE
    }
    finally { $ErrorActionPreference = $previousErrorAction }
    if ($encoderExit -ne 0) { throw "FFmpeg failed ($Label). Inspect $logPath" }

}
$WorkDirectory = [System.IO.Path]::GetFullPath($WorkDirectory)
New-Item -ItemType Directory -Path $WorkDirectory -Force | Out-Null
$logPath = Join-Path $WorkDirectory 'render.log'
[System.IO.File]::WriteAllText($logPath, '', $utf8)
$fontDirectory = Join-Path $WorkDirectory 'fonts'
New-Item -ItemType Directory -Path $fontDirectory -Force | Out-Null
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/fonts/Roboto-Variable.ttf') -Destination $fontDirectory -Force
Copy-Item -LiteralPath (Join-Path $projectRoot 'assets/fonts/Roboto-OFL.txt') -Destination $WorkDirectory -Force

$ass = @'
[Script Info]
Title: Antonio Luna - Maikling Kuwento ng Isang Heneral
ScriptType: v4.00+
PlayResX: 1280
PlayResY: 720
WrapStyle: 2
ScaledBorderAndShadow: yes

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Subtitle,Roboto,34,&H00FFFFFF,&H00FFFFFF,&H000E1825,&H80000000,-1,0,0,0,100,100,0,0,1,2.5,1,2,64,64,40,1
Style: Title,Roboto,32,&H00D9ECFF,&H00D9ECFF,&H000E1825,&H80000000,-1,0,0,0,100,100,0,0,1,2.5,1,8,64,64,64,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
Dialogue: 1,0:00:00.00,0:00:04.00,Title,,0,0,0,,{\pos(900,100)\fad(300,250)\fs42}Antonio Luna{\fs30}\NMaikling Kuwento ng Isang Heneral
'@
$ass += "`n"
$audioArgs = @('-hide_banner', '-loglevel', 'warning', '-y')
$audioFilters = @()
$audioLabels = ''
$audioIndex = 0
$expectedFrameStart = 0
foreach ($scene in $data.scenes) {
    if ($scene.frame_start -ne $expectedFrameStart -or $scene.frame_count -ne [Math]::Round($scene.duration_seconds * 24)) {
        throw "Invalid scene frame boundary: $($scene.id)"
    }
    $expectedFrameStart += $scene.frame_count
    foreach ($cue in $scene.subtitle_cues) {
        $clipPath = ResourcePath $cue.audio_file
        if (-not (Test-Path -LiteralPath $clipPath)) { throw "Missing voice clip: $clipPath" }
        if ($cue.start_seconds -lt $scene.start_seconds -or $cue.end_seconds -gt $scene.end_seconds) { throw 'Caption exceeds its scene.' }
        $audioArgs += @('-i', $clipPath)
        $delayMs = [int][Math]::Round($cue.start_seconds * 1000)
        $audioFilters += "[$($audioIndex):a]aresample=48000,aformat=channel_layouts=mono,adelay=$($delayMs):all=1[a$audioIndex]"
        $audioLabels += "[a$audioIndex]"
        $audioIndex++
        $captionText = $cue.text.Replace("`r", '').Replace("`n", '\N')
        if ($captionText.Contains('{') -or $captionText.Contains('}')) { throw 'Unexpected ASS control characters.' }
        $ass += "Dialogue: 0,$(AssTime $cue.start_seconds),$(AssTime $cue.end_seconds),Subtitle,,0,0,0,,$captionText`n"
    }
}
if ($expectedFrameStart -ne $data.format.total_frames) { throw 'Incorrect total frame count.' }
[System.IO.File]::WriteAllText((Join-Path $WorkDirectory 'captions.ass'), $ass, $utf8)
$total = Number $data.format.total_duration_seconds
$audioFilters += "$($audioLabels)amix=inputs=$($audioIndex):normalize=0,loudnorm=I=-17:TP=-1.5:LRA=7:print_format=json,aresample=48000,apad=whole_dur=$total,atrim=duration=$total[audio]"
$audioArgs += @('-filter_complex', ($audioFilters -join ';'), '-map', '[audio]', '-ac', '1', '-ar', '48000', '-c:a', 'pcm_s24le', (Join-Path $WorkDirectory 'narration.wav'))
RunFFmpeg $audioArgs 'Mixing the measured Tagalog narration without changing its speed.'

$concatLines = @()
foreach ($scene in $data.scenes) {
    $animation = $scene.animation
    $frames = [int]$scene.frame_count
    $last = $frames - 1
    $z0 = Number $animation.zoom_start
    $zd = Number ($animation.zoom_end - $animation.zoom_start)
    $cx0 = Number $animation.center_start[0]
    $cxd = Number ($animation.center_end[0] - $animation.center_start[0])
    $cy0 = Number $animation.center_start[1]
    $cyd = Number ($animation.center_end[1] - $animation.center_start[1])
    $zoom = "$z0+($zd)*on/$last"
    $x = "iw*($cx0+($cxd)*on/$last)-iw/zoom/2"
    $y = "ih*($cy0+($cyd)*on/$last)-ih/zoom/2"
    $fadeOutStart = Number ($scene.duration_seconds - $animation.fade_out_seconds)
    $fadeIn = Number $animation.fade_in_seconds
    $fadeOut = Number $animation.fade_out_seconds
    $filter = "scale=2560:1440:force_original_aspect_ratio=increase,crop=2560:1440,zoompan=z='$zoom':x='$x':y='$y':d=1:s=1280x720:fps=24,setsar=1,fade=t=in:st=0:d=$fadeIn,fade=t=out:st=$($fadeOutStart):d=$fadeOut,format=yuv420p"
    $clipName = 'scene_{0:00}.mp4' -f [int]$scene.id
    RunFFmpeg @('-hide_banner', '-loglevel', 'warning', '-y', '-loop', '1', '-framerate', '24', '-i', (ResourcePath $scene.media_production.illustration_file), '-vf', $filter, '-frames:v', "$frames", '-an', '-c:v', 'libx264', '-preset', 'fast', '-crf', '20', '-threads', '4', (Join-Path $WorkDirectory $clipName)) "Rendering scene $($scene.id)/6: $($scene.title)"
    $concatLines += "file '$clipName'"
}
[System.IO.File]::WriteAllLines((Join-Path $WorkDirectory 'scenes.txt'), $concatLines, $utf8)
$master = ResourcePath $data.production.master
$runtime = ResourcePath $data.production.runtime
Push-Location $WorkDirectory
try {
    RunFFmpeg @('-hide_banner', '-loglevel', 'info', '-y', '-f', 'concat', '-safe', '0', '-i', 'scenes.txt', '-i', 'narration.wav', '-vf', "ass=filename='captions.ass':fontsdir='fonts'", '-map', '0:v:0', '-map', '1:a:0', '-frames:v', "$expectedFrameStart", '-t', $total, '-c:v', 'libx264', '-preset', 'fast', '-crf', '21', '-pix_fmt', 'yuv420p', '-threads', '4', '-c:a', 'aac', '-b:a', '160k', '-ac', '1', '-ar', '48000', '-movflags', '+faststart', '-metadata', "title=$($data.title)", '-metadata', 'comment=Original AI-illustrated educational short; synthetic Tagalog narration; six scenes; no third-party film or music.', $master) 'Burning readable Filipino subtitles and writing the reviewable MP4.'
    RunFFmpeg @('-hide_banner', '-loglevel', 'warning', '-y', '-i', $master, '-map', '0:v:0', '-map', '0:a:0', '-c:v', 'libtheora', '-q:v', '6', '-pix_fmt', 'yuv420p', '-threads', '4', '-c:a', 'libvorbis', '-q:a', '4', '-ar', '48000', '-ac', '1', '-metadata', "title=$($data.title)", $runtime) 'Writing native Godot Theora/Vorbis video for Level 4.'
}
finally { Pop-Location }
Write-Output "Rendered $expectedFrameStart frames / $total seconds, exactly six scenes."
Write-Output $master
Write-Output $runtime
