{ self }:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.helix;
  defaultPackage = self.packages.${pkgs.stdenv.hostPlatform.system}.default;

  pluginType =
    { name, ... }:
    {
      options = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Whether to install this Helix Steel plugin.";
        };

        package = lib.mkOption {
          type = lib.types.nullOr lib.types.package;
          default = if name == "helix-fcitx-focus" then defaultPackage else null;
          defaultText = lib.literalExpression "null";
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
          default = if name == "helix-fcitx-focus" then [ "libhelix_fcitx_focus.so" ] else [ ];
          example = [ "libhelix_fcitx_focus.so" ];
          description = "Native Steel libraries from the package lib directory to install.";
        };
      };
    };

  enabledPlugins = lib.filterAttrs (_: plugin: plugin.enable) cfg.plugins;
  installablePlugins = lib.filterAttrs (_: plugin: plugin.package != null) enabledPlugins;
  missingPackagePlugins = lib.attrNames (
    lib.filterAttrs (_: plugin: plugin.package == null) enabledPlugins
  );

  pluginFiles = lib.mapAttrs' (
    name: plugin:
    lib.nameValuePair "helix/${plugin.helixConfigPath}" {
      source = "${plugin.package}/${plugin.cogsPath}";
    }
  ) installablePlugins;

  dylibFiles = lib.concatMapAttrs (
    _: plugin:
    lib.genAttrs plugin.dylibs (dylib: {
      source = "${plugin.package}/lib/${dylib}";
    })
  ) installablePlugins;
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

  config = lib.mkIf (enabledPlugins != { }) {
    assertions = [
      {
        assertion = missingPackagePlugins == [ ];
        message = "Helix Steel plugins need a package: ${lib.concatStringsSep ", " missingPackagePlugins}";
      }
    ];

    xdg.configFile = lib.mkIf (installablePlugins != { }) pluginFiles;

    xdg.dataFile = lib.mkIf (installablePlugins != { }) (
      lib.mapAttrs' (dylib: file: lib.nameValuePair "steel/native/${dylib}" file) dylibFiles
    );
  };
}
