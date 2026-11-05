param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression.FileSystem

$documents = @(
    @{ Level = 1; HeroId = "lapulapu"; File = "Level 1- Lapu-lapu.docx" },
    @{ Level = 2; HeroId = "andres_bonifacio"; File = "Level 2- Andres Bonifacio.docx" },
    @{ Level = 3; HeroId = "jose_rizal"; File = "Level 3- Jose Rizal.docx" },
    @{ Level = 4; HeroId = "antonio_luna"; File = "Level 4- Antonio Luna.docx" },
    @{ Level = 5; HeroId = "melchora_aquino"; File = "Level 5- Melchora Aquino.docx" },
    @{ Level = 6; HeroId = "apolinario_mabini"; File = "Level 6-Apolinario Mabini.docx" }
)

# A/B/C are zero-based multiple-choice keys after conversion. T/F map to the
# two visible True/False buttons. X means the source item needs historical or
# editorial review and must remain excluded from active gameplay.
$answerMaps = @{
    1 = "B C X A F B A F A T B A B B T A T A A F B B T A T B T A F B T X T A T B B T B B T X A F C T A T B T"
    2 = "B A F A T B T A A T B A A T A B T B T B T A B T B B A F A T B A T B F A A T A T A T A B T A T X T A"
    3 = "A A T A A F A X X T A B T A A X X T A T A A T A T A A A T A T A A T A X T A T A A T A T A A T A T A"
    4 = "A A T A T A T A T X A T A T A T A T A T A T A T A A T A T A T X F A T X T A T A X X T X T A T A T A"
    5 = "A A T A F A T A T A A T A T A F A T A T A T A F A A T A T A F A X X A A T A T A T X T A F A X X T A"
    6 = "A A F A T A T A T A A T A A T X T A T A T A T A F A T A T A T A A X A A X A T A T A T A T A T A T A"
}

$issues = @{
    "1:3" = "The phrase 'first national hero' is widely repeated but is not the wording used by the NHCP marker, which says Lapulapu was the first Filipino to repel European aggression. Rewrite or add an approved source before activation."
    "1:32" = "Mactan Strait is the channel between Mactan and Cebu; saying that it surrounds the whole island is geographically imprecise."
    "1:42" = "The combined claim about both coins and banknotes needs a precise denomination, series, and authoritative BSP citation."
    "2:48" = "No option correctly names a university: Bonifacio Global City is not a university, 'Bonifacio State University' is not a recognized answer, and option C does not answer the question."
    "3:8" = "Authorship of 'Sa Aking Mga Kabata' is disputed and should not be presented as an established childhood work without qualification."
    "3:9" = "The claimed favorite pet and animal names are not adequately supported by the selected authoritative sources."
    "3:16" = "The exact number of languages Rizal spoke varies across secondary accounts; 'over 20' needs a precise authoritative citation."
    "3:17" = "The answer inaccurately says Doctor of Medicine; Rizal earned a Licentiate in Medicine and a Licentiate in Philosophy and Letters."
    "3:36" = "Rizal was charged with rebellion, sedition, and conspiracy; saying that he led the Katipunan revolution is misleading because he did not lead it."
    "4:10" = "The answer combines chemistry with yellow fever, while Luna's documented medical research concerned malaria. Revise the choice before activation."
    "4:32" = "The alleged last words vary by retelling and are not securely documented in the selected authoritative sources."
    "4:36" = "The question asks for one province while the answer names municipalities in multiple provinces, so it has no single unambiguous answer."
    "4:41" = "The claim that Juan Luna painted a famous portrait of Antonio needs an authoritative museum or catalog citation."
    "4:42" = "The quotation is popularized by modern dramatization and lacks reliable primary attribution to Antonio Luna."
    "4:44" = "The answer names generic medals rather than one specific award tied to Luna; the premise is unsupported."
    "5:33" = "The claim that Aquino declined government pensions and financial aid needs an authoritative citation."
    "5:34" = "The supplied March 2, 1919 date conflicts with NHCP markers, which record February 1919. The item must be corrected and approved."
    "5:42" = "The specific menu of rice, chicken broth, and native dishes is not supported precisely enough for a single factual answer."
    "5:47" = "The claim that her Banlat home was burned by Spanish forces needs authoritative verification."
    "5:48" = "The phrase 'official government award' is too vague; multiple Tandang Sora awards exist and the issuing body is unspecified."
    "6:16" = "Mabini wrote constitutional programs and advised the republic, but Congress drafted the Malolos Constitution; the question also wrongly describes it as proclaimed in Kawit."
    "6:34" = "The precise claim that thousands attended Mabini's funeral needs an authoritative citation."
    "6:37" = "The legal scope and current status of a birthday holiday across Batangas need a specific proclamation or ordinance."
}

$references = @{
    1 = @(
        "https://philhistoricsites.nhcp.gov.ph/registry_database/lapulapu/",
        "https://philhistoricsites.nhcp.gov.ph/registry_database/mactan-ruta-ng-ekspedisyon-magallanes-elcano-sa-pilipinas/"
    )
    2 = @(
        "https://philhistoricsites.nhcp.gov.ph/registry_database/andres-bonifacio-30-nobyembre-1863-10-mayo-1897-2/",
        "https://philhistoricsites.nhcp.gov.ph/registry_database/andres-bonifacio-1863-1897/"
    )
    3 = @(
        "https://philhistoricsites.nhcp.gov.ph/registry_database/jose-rizal-1861-1896-calamba-church/",
        "https://philhistoricsites.nhcp.gov.ph/registry_database/rizal-shrine-fort-santiago/"
    )
    4 = @(
        "https://philhistoricsites.nhcp.gov.ph/registry_database/antonio-luna-1866-1899/",
        "https://philhistoricsites.nhcp.gov.ph/registry_database/sinilangang-pook-ni-heneral-antonio-luna-1866-1899/"
    )
    5 = @(
        "https://philhistoricsites.nhcp.gov.ph/registry_database/melchora-aquino-tandang-sora/",
        "https://philhistoricsites.nhcp.gov.ph/registry_database/ang-dambana-ni-melchora-tandang-sora-aquino-6-enero-1812-19-pebrero-1919/"
    )
    6 = @(
        "https://philhistoricsites.nhcp.gov.ph/registry_database/birthplace-of-mabini/",
        "https://philhistoricsites.nhcp.gov.ph/registry_database/apolinario-mabini-national-monument/",
        "https://philhistoricsites.nhcp.gov.ph/registry_database/mabini-shrine-pup/"
    )
}

function Get-DocumentParagraphs([string]$Path) {
    $archive = [System.IO.Compression.ZipFile]::OpenRead($Path)
    try {
        $entry = $archive.GetEntry("word/document.xml")
        if ($null -eq $entry) { throw "Missing word/document.xml in $Path" }
        $reader = [System.IO.StreamReader]::new($entry.Open())
        try { [xml]$xml = $reader.ReadToEnd() } finally { $reader.Dispose() }
        $namespaces = [System.Xml.XmlNamespaceManager]::new($xml.NameTable)
        $namespaces.AddNamespace("w", "http://schemas.openxmlformats.org/wordprocessingml/2006/main")
        return @(
            $xml.SelectNodes("//w:body/w:p | //w:body/w:tbl/w:tr/w:tc/w:p", $namespaces) |
                ForEach-Object {
                    (($_.SelectNodes(".//w:t", $namespaces) | ForEach-Object { $_.'#text' }) -join "").Trim()
                } |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
        )
    } finally {
        $archive.Dispose()
    }
}

function Convert-AnswerToken([string]$Token, [string]$Type) {
    if ($Token -eq "X") { return -1 }
    if ($Type -eq "true_false") {
        if ($Token -eq "T") { return 0 }
        if ($Token -eq "F") { return 1 }
        throw "Invalid True/False key '$Token'."
    }
    $index = "ABC".IndexOf($Token)
    if ($index -lt 0) { throw "Invalid multiple-choice key '$Token'." }
    return $index
}

$records = [System.Collections.Generic.List[object]]::new()
$counts = @{}
foreach ($document in $documents) {
    $level = [int]$document.Level
    $documentPath = Join-Path (Join-Path $ProjectRoot "Question_Documents") $document.File
    if (-not (Test-Path -LiteralPath $documentPath)) { throw "Missing source document: $documentPath" }
    $paragraphs = Get-DocumentParagraphs $documentPath
    $tokens = @($answerMaps[$level] -split " ")
    if ($tokens.Count -ne 50) { throw "Level $level answer map has $($tokens.Count) entries instead of 50." }
    $questionNumber = 0
    for ($index = 0; $index -lt $paragraphs.Count; $index++) {
        if ($paragraphs[$index] -notmatch "^(Multiple Choice|True or False):\s*(.+)$") { continue }
        $questionNumber++
        $type = if ($Matches[1] -eq "Multiple Choice") { "multiple_choice" } else { "true_false" }
        $questionText = $Matches[2].Trim()
        $choices = if ($type -eq "multiple_choice") {
            @(
                ($paragraphs[$index + 1] -replace "^A\)\s*", "")
                ($paragraphs[$index + 2] -replace "^B\)\s*", "")
                ($paragraphs[$index + 3] -replace "^C\)\s*", "")
            )
        } else {
            @("True", "False")
        }
        $token = $tokens[$questionNumber - 1]
        if (($type -eq "multiple_choice" -and @("T", "F").Contains($token)) -or
            ($type -eq "true_false" -and @("A", "B", "C").Contains($token))) {
            throw "Level $level question $questionNumber has incompatible key '$token' for type '$type'."
        }
        $correctIndex = Convert-AnswerToken $token $type
        $issueKey = "$level`:$questionNumber"
        $status = if ($token -eq "X") { "needs_review" } else { "verified" }
        $correctAnswer = if ($correctIndex -ge 0) { [string]$choices[$correctIndex] } else { "" }
        $records.Add([ordered]@{
            id = "HR-L$level-Q$($questionNumber.ToString('00'))"
            source_number = $questionNumber
            level = $level
            hero_id = [string]$document.HeroId
            type = $type
            question = $questionText
            choices = @($choices)
            correct_index = $correctIndex
            correct_answer = $correctAnswer
            validation_status = $status
            active = ($status -eq "verified")
            validation_issue = if ($issues.ContainsKey($issueKey)) { $issues[$issueKey] } else { "" }
            source_document = [string]$document.File
            source_question = $questionText
            source_choices = @($choices)
            references = @($references[$level])
        })
    }
    if ($questionNumber -ne 50) { throw "$($document.File) contains $questionNumber parsed questions instead of 50." }
    $counts["$level"] = $questionNumber
}

if ($records.Count -ne 300) { throw "Parsed $($records.Count) questions instead of 300." }
$verifiedCount = @($records | Where-Object { $_.validation_status -eq "verified" }).Count
$reviewCount = $records.Count - $verifiedCount
$payload = [ordered]@{
    schema_version = 1
    source_question_count = $records.Count
    verified_question_count = $verifiedCount
    review_question_count = $reviewCount
    active_question_count = $verifiedCount
    questions_per_level = $counts
    questions = @($records)
}

$outputDirectory = Join-Path $ProjectRoot "data"
[System.IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
$outputPath = Join-Path $outputDirectory "quiz_questions.json"
$json = $payload | ConvertTo-Json -Depth 12
[System.IO.File]::WriteAllText($outputPath, $json, [System.Text.UTF8Encoding]::new($false))
Write-Output "Wrote $($records.Count) source questions to $outputPath ($verifiedCount verified, $reviewCount review-only)."
