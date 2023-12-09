{...}: {
  home.username = "verdek";
  home.homeDirectory = "/home/verdek";

  imports = [
    ../home.nix
  ];
}
