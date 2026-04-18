{
  programs.workmux = {
    enable = true;
    package = null;
    settings = {
      multiplexer = "tmux";
      default_agent = "claude";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/workmux/config.yaml
    assertFileContent home-files/.config/workmux/config.yaml \
      ${./expected-config.yaml}
  '';
}
