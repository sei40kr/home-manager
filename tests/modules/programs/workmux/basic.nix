{
  programs.workmux = {
    enable = true;
    package = null;
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/workmux/config.yaml
  '';
}
