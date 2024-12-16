{
  pkgs,
  lib,
  check ? true,
  ...
}: let
  moduleSingleton = [
    ./module.nix
  ];

  pkgsModule = {config, ...}: {
    config = {
      _module.args.baseModules = moduleSingleton;
      _module.args.pkgsPath = pkgs.path;
      _module.args.pkgs = lib.mkDefault pkgs;
      _module.check = check;
    };
  };
in
  moduleSingleton ++ [pkgsModule]
