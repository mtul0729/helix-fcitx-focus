{ config, lib, ... }:

let
  cfg = config.programs.helix;

  pluginType =
    { name, ... }:
    {
      options = {
        package = lib.mkOption {
          type = lib.types.package;
          description = ''
            Package containing the Steel plugin files.

            The package is expected to expose Scheme files under
            share/steel/cogs/<plugin-name> and native libraries under lib.
          '';
        };

        cogsPath = lib.mkOption {
          type = lib.types.str;
          default = "share/steel/cogs/${name}";
          description = "Path inside the package that contains the plugin's Steel cog files.";
        };

        helixConfigPath = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Path under the Helix config directory where the plugin's Steel cog files are linked.";
        };

        dylibs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          example = [ "libhelix_fcitx_focus.so" ];
          description = "Native Steel libraries from the package lib directory to install.";
        };
      };
    };

  pluginFiles = lib.mapAttrs' (
    name: plugin:
    lib.nameValuePair "helix/${plugin.helixConfigPath}" {
      source = "${plugin.package}/${plugin.cogsPath}";
    }
  ) cfg.plugins;

  dylibFiles = lib.concatMapAttrs (
    _: plugin:
    lib.genAttrs plugin.dylibs (dylib: {
      source = "${plugin.package}/lib/${dylib}";
    })
  ) cfg.plugins;
in
{
  options.programs.helix = {
    plugins = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule pluginType);
      default = { };
      description = ''
        Steel plugins to install for Helix.

        Plugins are installed into the user Steel data directory, so Helix can
        load them from init.scm with paths such as
        "plugin-name/cogs/plugin.scm".
      '';
    };
  };

  config = lib.mkIf (cfg.plugins != { }) {
    xdg.configFile = pluginFiles;

    xdg.dataFile = lib.mapAttrs' (
      dylib: file: lib.nameValuePair "steel/native/${dylib}" file
    ) dylibFiles;
  };
}
