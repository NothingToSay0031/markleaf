using MarkLeaf.App;

namespace MarkLeaf.Tests;

[TestClass]
public sealed class LaunchOptionsTests
{
    [TestMethod]
    public void Parse_ReadsStage2SmokeCommandOptions()
    {
        var report = Path.GetFullPath("command-report.json");

        var options = LaunchOptions.Parse(
        [
            "--smoke-command", "ToggleFocusMode",
            "--command-report", report,
            "--editor-smoke-report", report,
            "--editor-web-root", ".\\editor-root",
            "--editor-state-report", report,
            "--editor-command-smoke", "setHeading1",
            "--editor-command-report", report,
            "--document-smoke-input", report,
            "--document-smoke-output", report,
            "--document-smoke-report", report,
        ]);

        Assert.AreEqual("ToggleFocusMode", options.SmokeCommand);
        Assert.AreEqual(report, options.CommandReportPath);
        Assert.AreEqual(report, options.EditorSmokeReportPath);
        Assert.AreEqual(Path.GetFullPath(".\\editor-root"), options.EditorWebRoot);
        Assert.AreEqual(report, options.EditorStateReportPath);
        Assert.AreEqual("setHeading1", options.EditorCommandSmoke);
        Assert.AreEqual(report, options.EditorCommandReportPath);
        Assert.AreEqual(report, options.DocumentSmokeInputPath);
        Assert.AreEqual(report, options.DocumentSmokeOutputPath);
        Assert.AreEqual(report, options.DocumentSmokeReportPath);
    }

    [TestMethod]
    public void Parse_ReadsInitialDocumentForNewWindow()
    {
        var path = Path.Combine(Path.GetTempPath(), "window.md");

        var options = LaunchOptions.Parse(["--open-document", path]);

        Assert.AreEqual(Path.GetFullPath(path), options.InitialDocumentPath);
    }

    [TestMethod]
    public void Parse_ReadsTrailingIsolatedWindowSwitch()
    {
        var options = LaunchOptions.Parse(["--isolated-file-window"]);

        Assert.IsTrue(options.IsolatedFileWindow);
    }

    [TestMethod]
    public void Parse_ReadsDocumentWithTrailingIsolatedWindowSwitch()
    {
        var path = Path.Combine(Path.GetTempPath(), "isolated-window.md");

        var options = LaunchOptions.Parse([
            "--open-document", path,
            "--isolated-file-window",
        ]);

        Assert.AreEqual(Path.GetFullPath(path), options.InitialDocumentPath);
        Assert.IsTrue(options.IsolatedFileWindow);
    }

    [TestMethod]
    public void Parse_ReadsExportConfigCommand()
    {
        var path = Path.Combine(Path.GetTempPath(), "export.json");

        var options = LaunchOptions.Parse(["export", "--config", path]);

        Assert.AreEqual(Path.GetFullPath(path), options.ExportConfigPath);
        Assert.IsTrue(options.IsExportCommand);
    }

    [TestMethod]
    public void Parse_ReadsBatchFriendlyExportCommand()
    {
        var input = Path.Combine(Path.GetTempPath(), "article.md");
        var output = Path.Combine(Path.GetTempPath(), "exports", "article.pdf");
        var config = Path.Combine(Path.GetTempPath(), "export.json");

        var options = LaunchOptions.Parse(["export", input, "-o", output, "-c", config]);

        Assert.IsTrue(options.IsExportCommand);
        Assert.AreEqual(Path.GetFullPath(input), options.ExportInputPath);
        Assert.AreEqual(Path.GetFullPath(output), options.ExportOutputPath);
        Assert.AreEqual(Path.GetFullPath(config), options.ExportConfigPath);
    }

    [TestMethod]
    public void Parse_ReadsExportInputWithoutOptionalArguments()
    {
        var input = Path.Combine(Path.GetTempPath(), "article.md");

        var options = LaunchOptions.Parse(["export", input]);

        Assert.IsTrue(options.IsExportCommand);
        Assert.AreEqual(Path.GetFullPath(input), options.ExportInputPath);
        Assert.IsNull(options.ExportOutputPath);
        Assert.IsNull(options.ExportConfigPath);
    }

    [TestMethod]
    public void Parse_ResolvesRelativeExportPathsFromCurrentDirectory()
    {
        var options = LaunchOptions.Parse([
            "export", @"documents\article.md",
            "-o", @"exports\article.pdf",
            "-c", @"configs\export.json",
        ]);

        Assert.AreEqual(Path.GetFullPath(@"documents\article.md"), options.ExportInputPath);
        Assert.AreEqual(Path.GetFullPath(@"exports\article.pdf"), options.ExportOutputPath);
        Assert.AreEqual(Path.GetFullPath(@"configs\export.json"), options.ExportConfigPath);
    }

    [TestMethod]
    public void ExportConfig_ResolvesRelativePathsFromConfigDirectory()
    {
        var configDirectory = Path.Combine(Path.GetTempPath(), "markleaf-config");

        Assert.AreEqual(
            Path.GetFullPath(Path.Combine(configDirectory, @"documents\article.md")),
            CommandLineExportOptions.ResolvePath(@"documents\article.md", configDirectory));
    }

    [TestMethod]
    public async Task ExportConfig_ReadsNestedOptions()
    {
        var path = Path.Combine(Path.GetTempPath(), $"markleaf-export-{Guid.NewGuid():N}.json");
        try
        {
            await File.WriteAllTextAsync(path, """
                {
                  "input": "article.md",
                  "output": "article.pdf",
                  "format": "pdf",
                  "paper": { "size": "A5", "orientation": "landscape" },
                  "image": { "contentWidth": 1440, "scale": 3 }
                }
                """);

            var options = await CommandLineExportOptions.LoadAsync(path);

            Assert.AreEqual("article.md", options.Input);
            Assert.AreEqual("A5", options.Paper.Size);
            Assert.AreEqual("landscape", options.Paper.Orientation);
            Assert.AreEqual(1440, options.Image.ContentWidth);
            Assert.AreEqual(3f, options.Image.Scale);
        }
        finally
        {
            File.Delete(path);
        }
    }
}
