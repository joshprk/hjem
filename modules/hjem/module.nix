{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib.modules) mkIf mkDefault;
  inherit (lib.options) mkOption mkEnableOption;
  inherit (lib.strings) hasPrefix concatStringsSep;
  inherit (lib.lists) filter map;
  inherit (lib.attrsets) filterAttrs mapAttrs' attrValues;
  inherit (lib.types) bool submodule str path attrsOf nullOr lines;

  fileType = relativeTo:
    submodule ({
      name,
      target,
      config,
      ...
    }: {
      options = {
        enable = mkOption {
          type = bool;
          default = true;
          description = ''
            Whether this file should be generated. This option allows specific
            files to be disabled.
          '';
        };

        target = mkOption {
          type = str;
          apply = p:
            if hasPrefix "/" p
            then throw "This option cannot handle absolute paths yet!"
            else "${config.relativeTo}/${p}";
          defaultText = "name";
          description = ''
            Path to target file relative to ${config.relativeTo}.
          '';
        };

        text = mkOption {
          default = null;
          type = nullOr lines;
          description = ''
            Text of the file.
          '';
        };

        source = mkOption {
          type = nullOr path;
          default = null;
          description = ''
            Path of the source file or directory.
          '';
        };

        executable = mkOption {
          type = nullOr bool;
          default = false;
          description = ''
            Whether to set the execute bit on the target file.
          '';
        };

        clobber = mkOption {
          type = bool;
          default = false;
          example = true;
          description = ''
            Whether to "clobber" existing target paths. While `true`, tmpfile rules will be constructed
            with `L+` (*re*create) instead of `L` (create) type.
          '';
        };

        relativeTo = mkOption {
          internal = true;
          type = path;
          default = relativeTo;
          description = "Path to which symlinks will be relative to";
          apply = x:
            assert (hasPrefix "/" x || abort "Relative path ${x} cannot be used for files.<file>.relativeTo"); x;
        };
      };

      config = {
        target = mkDefault name;
        source = mkIf (config.text != null) (mkDefault (pkgs.writeTextFile {
          inherit name;
          inherit (config) text executable;
        }));
      };
    });
in {
  options = {
    enable = mkEnableOption "Whether to enable home management for ${config.homes.user}" // {default = true;};
    user = mkOption {
      type = str;
      default = "";
      description = "The owner of a given home directory.";
    };

    directory = mkOption {
      type = path;
      apply = toString;
      description = ''
        The home directory for the user, to which files configured in
        {option}`homes.<name>.files` will be relative to by default.
      '';
    };

    /*
    files = mkOption {
      default = {};
      type = attrsOf (fileType config.directory);
      description = "Files to be managed, inserted to relevant systemd-tmpfiles rules";
    };

    packages = mkOption {
      type = with lib.types; listOf package;
      default = [];
      description = "Packages for ${config.user}";
    };
    */
  };
}
