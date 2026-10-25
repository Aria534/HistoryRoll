param(
	[string]$Source = "assets/background/Whimsical HistoryRoll Garden Board.png",
	[string]$OutputDirectory = "assets/background/main_menu_foliage"
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$sourcePath = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $Source))
$outputPath = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputDirectory))
[System.IO.Directory]::CreateDirectory($outputPath) | Out-Null

Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;

public static class MainMenuFoliageBuilder
{
    private sealed class Region
    {
        public string Name;
        public Rectangle Bounds;
        public Point[] Polygon;

        public Region(string name, Rectangle bounds, Point[] polygon)
        {
            Name = name;
            Bounds = bounds;
            Polygon = polygon;
        }
    }

    public static void Build(string sourcePath, string outputDirectory)
    {
        using (var sourceFile = new Bitmap(sourcePath))
        using (var source = new Bitmap(sourceFile.Width, sourceFile.Height, PixelFormat.Format32bppArgb))
        {
            using (var graphics = Graphics.FromImage(source))
                graphics.DrawImageUnscaled(sourceFile, 0, 0);

            int width = source.Width;
            int height = source.Height;
            var regions = CreateRegions(width, height);
            var combinedMask = new bool[width * height];

            foreach (var region in regions)
            {
                bool[] mask = CreateMask(source, region);
                RetainEdgeConnectedFoliage(mask, width, height, region);
                Dilate(mask, width, height, 3);
                ConstrainToBounds(mask, width, height, region.Bounds);
                SaveOverlay(source, mask, region, outputDirectory);
                for (int i = 0; i < combinedMask.Length; i++)
                    combinedMask[i] |= mask[i];
            }

            using (var cleaned = CreateCleanBackground(source, combinedMask))
            {
                cleaned.Save(Path.Combine(outputDirectory, "main_menu_static.png"), ImageFormat.Png);
                ValidateNeutralComposite(source, cleaned, regions, outputDirectory);
            }
        }
    }

    private static Region[] CreateRegions(int width, int height)
    {
        // Coordinates are authored against the 941x1672 source artwork.
        double sx = width / 941.0;
        double sy = height / 1672.0;
        Func<int, int> x = value => (int)Math.Round(value * sx);
        Func<int, int> y = value => (int)Math.Round(value * sy);

        return new[]
        {
            MakeRegion("plant_top_left", x(0), y(0), x(375), y(215), new[] {
                P(x(0), y(0)), P(x(375), y(0)), P(x(350), y(150)),
                P(x(260), y(205)), P(x(145), y(180)), P(x(0), y(215)) }),
            MakeRegion("plant_top_right", x(430), y(0), x(511), y(225), new[] {
                P(x(430), y(0)), P(x(941), y(0)), P(x(941), y(225)),
                P(x(790), y(205)), P(x(675), y(145)), P(x(520), y(185)) }),
            MakeRegion("plant_left", x(0), y(150), x(235), y(870), new[] {
                P(x(0), y(150)), P(x(155), y(175)), P(x(225), y(360)),
                P(x(190), y(560)), P(x(235), y(820)), P(x(155), y(1020)), P(x(0), y(1020)) }),
            MakeRegion("plant_right", x(690), y(145), x(251), y(900), new[] {
                P(x(790), y(145)), P(x(941), y(145)), P(x(941), y(1045)),
                P(x(770), y(1010)), P(x(720), y(820)), P(x(745), y(590)), P(x(690), y(365)) }),
            MakeRegion("plant_bottom_left", x(0), y(825), x(420), y(847), new[] {
                P(x(0), y(825)), P(x(110), y(850)), P(x(125), y(1010)),
                P(x(120), y(1190)), P(x(205), y(1390)), P(x(420), y(1672)), P(x(0), y(1672)) }),
            MakeRegion("plant_bottom_right", x(565), y(820), x(376), y(852), new[] {
                P(x(900), y(820)), P(x(941), y(815)), P(x(941), y(1672)),
                P(x(565), y(1672)), P(x(715), y(1450)), P(x(850), y(1230)), P(x(900), y(1020)) })
        };
    }

    private static Region MakeRegion(string name, int left, int top, int width, int height, Point[] polygon)
    {
        return new Region(name, new Rectangle(left, top, width, height), polygon);
    }

    private static Point P(int x, int y) { return new Point(x, y); }

    private static bool[] CreateMask(Bitmap source, Region region)
    {
        int width = source.Width;
        int height = source.Height;
        var mask = new bool[width * height];
        Rectangle bounds = Rectangle.Intersect(region.Bounds, new Rectangle(0, 0, width, height));

        for (int py = bounds.Top; py < bounds.Bottom; py++)
        for (int px = bounds.Left; px < bounds.Right; px++)
        {
            if (!InsidePolygon(px, py, region.Polygon))
                continue;

            Color color = source.GetPixel(px, py);
            if (LooksLikeFoliage(color))
                mask[py * width + px] = true;
        }
        return mask;
    }

    private static bool LooksLikeFoliage(Color color)
    {
        double r = color.R / 255.0;
        double g = color.G / 255.0;
        double b = color.B / 255.0;
        double max = Math.Max(r, Math.Max(g, b));
        double min = Math.Min(r, Math.Min(g, b));
        double delta = max - min;
        double saturation = max <= 0.001 ? 0.0 : delta / max;
        double hue = 0.0;
        if (delta > 0.001)
        {
            if (max == r) hue = 60.0 * (((g - b) / delta) % 6.0);
            else if (max == g) hue = 60.0 * (((b - r) / delta) + 2.0);
            else hue = 60.0 * (((r - g) / delta) + 4.0);
            if (hue < 0.0) hue += 360.0;
        }

        bool leaf = hue >= 48.0 && hue <= 150.0 && saturation >= 0.24 &&
            max >= 0.10 && g >= r * 0.82 && g >= b * 1.04;
        return leaf;
    }

    private static bool InsidePolygon(int x, int y, Point[] polygon)
    {
        bool inside = false;
        for (int i = 0, j = polygon.Length - 1; i < polygon.Length; j = i++)
        {
            Point a = polygon[i];
            Point b = polygon[j];
            if (((a.Y > y) != (b.Y > y)) &&
                (x < (double)(b.X - a.X) * (y - a.Y) / (double)(b.Y - a.Y) + a.X))
                inside = !inside;
        }
        return inside;
    }

    private static void Dilate(bool[] mask, int width, int height, int radius)
    {
        var original = (bool[])mask.Clone();
        for (int y = 0; y < height; y++)
        for (int x = 0; x < width; x++)
        {
            if (!original[y * width + x]) continue;
            for (int oy = -radius; oy <= radius; oy++)
            for (int ox = -radius; ox <= radius; ox++)
            {
                int nx = x + ox;
                int ny = y + oy;
                if (nx >= 0 && nx < width && ny >= 0 && ny < height)
                    mask[ny * width + nx] = true;
            }
        }
    }

    private static void RetainEdgeConnectedFoliage(bool[] mask, int width, int height, Region region)
    {
        var visited = new bool[mask.Length];
        int[] offsetsX = { -1, 0, 1, -1, 1, -1, 0, 1 };
        int[] offsetsY = { -1, -1, -1, 0, 0, 1, 1, 1 };

        for (int start = 0; start < mask.Length; start++)
        {
            if (!mask[start] || visited[start]) continue;
            var component = new List<int>();
            var queue = new Queue<int>();
            bool touchesAttachmentEdge = false;
            visited[start] = true;
            queue.Enqueue(start);

            while (queue.Count > 0)
            {
                int index = queue.Dequeue();
                int x = index % width;
                int y = index / width;
                component.Add(index);
                touchesAttachmentEdge |= TouchesAttachmentEdge(region.Name, x, y, width, height);

                for (int direction = 0; direction < offsetsX.Length; direction++)
                {
                    int nx = x + offsetsX[direction];
                    int ny = y + offsetsY[direction];
                    if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
                    int next = ny * width + nx;
                    if (!mask[next] || visited[next]) continue;
                    visited[next] = true;
                    queue.Enqueue(next);
                }
            }

            if (!touchesAttachmentEdge)
                foreach (int index in component) mask[index] = false;
        }
    }

    private static bool TouchesAttachmentEdge(string name, int x, int y, int width, int height)
    {
        const int tolerance = 10;
        if (name.StartsWith("plant_top_")) return y <= tolerance;
        if (name == "plant_left") return x <= tolerance;
        if (name == "plant_right") return x >= width - tolerance - 1;
        if (name.StartsWith("plant_bottom_")) return y >= height - tolerance - 1;
        return false;
    }

    private static void ConstrainToBounds(bool[] mask, int width, int height, Rectangle bounds)
    {
        for (int y = 0; y < height; y++)
        for (int x = 0; x < width; x++)
        {
            if (!bounds.Contains(x, y))
                mask[y * width + x] = false;
        }
    }

    private static void SaveOverlay(Bitmap source, bool[] mask, Region region, string outputDirectory)
    {
        Rectangle crop = Rectangle.Intersect(region.Bounds, new Rectangle(0, 0, source.Width, source.Height));
        using (var overlay = new Bitmap(crop.Width, crop.Height, PixelFormat.Format32bppArgb))
        {
            for (int y = 0; y < crop.Height; y++)
            for (int x = 0; x < crop.Width; x++)
            {
                int sourceX = crop.Left + x;
                int sourceY = crop.Top + y;
                if (mask[sourceY * source.Width + sourceX])
                    overlay.SetPixel(x, y, source.GetPixel(sourceX, sourceY));
                else
                    overlay.SetPixel(x, y, Color.Transparent);
            }
            overlay.Save(Path.Combine(outputDirectory, region.Name + ".png"), ImageFormat.Png);
        }
    }

    private static Bitmap CreateCleanBackground(Bitmap source, bool[] mask)
    {
        int width = source.Width;
        int height = source.Height;
        var result = new Bitmap(source);
        int blurDivisor = 14;
        using (var small = new Bitmap(Math.Max(1, width / blurDivisor), Math.Max(1, height / blurDivisor), PixelFormat.Format32bppArgb))
        using (var blurred = new Bitmap(width, height, PixelFormat.Format32bppArgb))
        {
            using (var graphics = Graphics.FromImage(small))
            {
                graphics.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBilinear;
                graphics.PixelOffsetMode = System.Drawing.Drawing2D.PixelOffsetMode.HighQuality;
                graphics.DrawImage(source, new Rectangle(0, 0, small.Width, small.Height));
            }
            using (var graphics = Graphics.FromImage(blurred))
            {
                graphics.InterpolationMode = System.Drawing.Drawing2D.InterpolationMode.HighQualityBilinear;
                graphics.PixelOffsetMode = System.Drawing.Drawing2D.PixelOffsetMode.HighQuality;
                graphics.DrawImage(small, new Rectangle(0, 0, width, height));
            }

            for (int y = 0; y < height; y++)
            for (int x = 0; x < width; x++)
            {
                if (mask[y * width + x])
                    result.SetPixel(x, y, blurred.GetPixel(x, y));
            }
        }
        return result;
    }

    private static void ValidateNeutralComposite(Bitmap source, Bitmap cleaned, Region[] regions, string outputDirectory)
    {
        using (var composite = new Bitmap(cleaned))
        {
            using (var graphics = Graphics.FromImage(composite))
            {
                graphics.CompositingMode = System.Drawing.Drawing2D.CompositingMode.SourceOver;
                foreach (var region in regions)
                using (var overlay = new Bitmap(Path.Combine(outputDirectory, region.Name + ".png")))
                    graphics.DrawImageUnscaled(overlay, region.Bounds.Left, region.Bounds.Top);
            }

            for (int y = 0; y < source.Height; y++)
            for (int x = 0; x < source.Width; x++)
            {
                if (source.GetPixel(x, y).ToArgb() != composite.GetPixel(x, y).ToArgb())
                    throw new InvalidDataException("Neutral foliage composite changed source pixel " + x + "," + y + ".");
            }
        }
    }

}
'@ -ReferencedAssemblies System.Drawing

[MainMenuFoliageBuilder]::Build($sourcePath, $outputPath)
Write-Output "Generated foliage assets in $outputPath"
