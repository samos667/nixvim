{
  empty = {
    plugins.wezterm.enable = true;
  };

  default = {
    plugins.wezterm = {
      enable = true;
      settings.create_commands = true;
    };
  };
}
