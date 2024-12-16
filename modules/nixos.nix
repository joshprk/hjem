{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.options) mkOption;
  inherit (lib.types) attrsOf submoduleWith;
  inherit (lib.strings) concatStringsSep;
  inherit (lib.lists) filter map;
  inherit (lib.attrsets) filterAttrs mapAttrs' attrValues;

  hjemModule = submoduleWith {
    description = "NixOS module for Hjem";
    class = "hjem";

    specialArgs = {inherit lib;};

    modules = [
      ({name, ...}: {
        imports = import ./hjem {inherit pkgs lib;};

        config = {
          username = config.users.users.${name}.name;
          directory = config.users.users.${name}.home;
        };
      })
    ];
  };
in {
  options.homes = mkOption {
    type = attrsOf hjemModule;
    default = {};
    visible = "shallow";
    description = ''
      Individual home configurations to be managed by Hjem.
    '';
  };

  config = {
    users.users = mapAttrs' (name: {packages, ...}: {
      inherit name;
      value.packages = packages;
    }) (filterAttrs (_: u: u.packages != []) config.homes);

    systemd.user.tmpfiles.users = mapAttrs' (name: {files, ...}: {
      inherit name;
      value.rules = map (
        file: let
          # L+ will recrate, i.e., clobber existing files.
          mode =
            if file.clobber
            then "L+"
            else "L";

          # Constructed rule string that consists of the type, target, and source
          # of a tmpfile. Files with 'null' sources are filtered before the rule
          # is constructed.
          ruleString = [mode file.target "- - - -" file.source];
        in
          concatStringsSep " " ruleString
      ) (filter (f: f.enable && f.source != null) (attrValues files));
    }) (filterAttrs (_: u: u.files != {}) config.homes);
  };
}
