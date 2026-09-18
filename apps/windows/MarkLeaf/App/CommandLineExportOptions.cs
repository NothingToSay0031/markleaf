using System.Text.Json;

namespace MarkLeaf.App;

internal sealed class CommandLineExportOptions
{
    public string Input { get; set; } = "";
    public string Output { get; set; } = "";
    public string Format { get; set; } = "pdf";
    public string? Style { get; set; }
    public string? ColorScheme { get; set; }
    public PaperOptions Paper { get; set; } = new();
    public HeaderFooterOptions Header { get; set; } = new();
    public HeaderFooterOptions Footer { get; set; } = new();
    public HtmlOptions Html { get; set; } = new();
    public LayoutOptions Layout { get; set; } = new();
    public ImageOptions Image { get; set; } = new();
    public RuntimeOptions Runtime { get; set; } = new();
    public string? Report { get; set; }
    public bool Overwrite { get; set; }

    public static string ResolvePath(string path, string? baseDirectory = null)
    {
        if (string.IsNullOrWhiteSpace(path)) return path;
        if (Path.IsPathRooted(path)) return Path.GetFullPath(path);
        return Path.GetFullPath(path, baseDirectory ?? Environment.CurrentDirectory);
    }

    public static async Task<CommandLineExportOptions> LoadAsync(string path)
    {
        await using var stream = File.OpenRead(path);
        return await JsonSerializer.DeserializeAsync<CommandLineExportOptions>(stream,
            new JsonSerializerOptions { PropertyNameCaseInsensitive = true })
            ?? throw new InvalidDataException("Export configuration is empty.");
    }
}

internal sealed class PaperOptions
{
    public string Size { get; set; } = "A4";
    public string Orientation { get; set; } = "portrait";
    public MarginOptions Margin { get; set; } = new();
}

internal sealed class MarginOptions
{
    public float Top { get; set; } = 25.4f;
    public float Bottom { get; set; } = 25.4f;
    public float Left { get; set; } = 31.7f;
    public float Right { get; set; } = 31.7f;
}

internal sealed class HeaderFooterOptions
{
    public string Text { get; set; } = "";
    public string Alignment { get; set; } = "center";
}

internal sealed class HtmlOptions
{
    public string Header { get; set; } = "";
    public string Footer { get; set; } = "";
    public string? Title { get; set; }
}

internal sealed class LayoutOptions
{
    public bool KeepTablesTogether { get; set; }
    public bool KeepHeadingsWithNextBlock { get; set; }
}

internal sealed class ImageOptions
{
    public int ContentWidth { get; set; } = 1200;
    public float Scale { get; set; } = 2f;
    public int MaxHeight { get; set; } = 12000;
    public string Format { get; set; } = "png";
    public int JpegQuality { get; set; } = 90;
}

internal sealed class RuntimeOptions
{
    public int TimeoutSeconds { get; set; } = 120;
}
