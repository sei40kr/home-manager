{
  programs.workmux = {
    enable = true;
    package = null;
  };

  programs.opencode.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/opencode/plugins/workmux-status.ts
    assertFileRegex home-files/.config/opencode/plugins/workmux-status.ts \
      'WorkmuxStatusPlugin'
    assertFileRegex home-files/.config/opencode/plugins/workmux-status.ts \
      'workmux set-window-status'

    assertFileExists home-files/.config/opencode/package.json
    assertFileRegex home-files/.config/opencode/package.json \
      '"@opencode-ai/plugin"'
    assertFileRegex home-files/.config/opencode/package.json '"1.4.3"'
  '';
}
