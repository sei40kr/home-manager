{
  programs.workmux = {
    enable = true;
    package = null;
  };

  programs.gemini-cli = {
    enable = true;
    package = null;
  };

  nmt.script = ''
    assertFileExists home-files/.gemini/settings.json
    assertFileRegex home-files/.gemini/settings.json '"BeforeAgent"'
    assertFileRegex home-files/.gemini/settings.json '"Notification"'
    assertFileRegex home-files/.gemini/settings.json '"ToolPermission"'
    assertFileRegex home-files/.gemini/settings.json '"AfterTool"'
    assertFileRegex home-files/.gemini/settings.json '"AfterAgent"'
    assertFileRegex home-files/.gemini/settings.json '"SessionEnd"'
    assertFileRegex home-files/.gemini/settings.json 'workmux set-window-status working'
    assertFileRegex home-files/.gemini/settings.json 'workmux set-window-status waiting'
    assertFileRegex home-files/.gemini/settings.json 'workmux set-window-status done'
  '';
}
