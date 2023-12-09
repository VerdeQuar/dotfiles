{...}: {
  home.username = "root";
  home.homeDirectory = "/root";

  imports = [
    ../home.nix
  ];
}
