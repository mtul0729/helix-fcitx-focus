# helix-fcitx-focus

[简体中文](README.zh-CN.md)

Steel plugin for Helix that keeps fcitx5 in English outside insert mode and
restores the previous active input method when entering insert mode.

This is useful for Chinese/Japanese/Korean input workflows where normal-mode
keys should stay ASCII, while insert mode should resume the input method you
were using before leaving insert mode.

## Requirements

- Helix built with Steel support from the `steel-event-system` branch.
- fcitx5 running on the user session bus.

## Install with Forge

Install the plugin with Forge:

```sh
forge pkg install --git https://github.com/mtul0729/helix-fcitx-focus
```

Then load the plugin from `~/.config/helix/init.scm`:

```scheme
(require "helix-fcitx-focus/cogs/fcitx-focus.scm")
```

## NixOS / Home Manager

This repository also exposes a flake package and Home Manager module for
declarative installations:

```nix
{
  inputs.helix-fcitx-focus.url = "github:mtul0729/helix-fcitx-focus";

  outputs =
    { helix-fcitx-focus, ... }:
    {
      # In a Home Manager module:
      home-manager.users.example =
        { pkgs, ... }:
        {
          imports = [
            helix-fcitx-focus.homeManagerModules.default
          ];

          programs.helix.plugins.helix-fcitx-focus.enable = true;

          xdg.configFile."helix/init.scm".text = ''
            (require "helix-fcitx-focus/cogs/fcitx-focus.scm")
          '';
        };
    };
}
```

## Development

For local development from this repository:

```sh
nix develop
cargo steel-lib
mkdir -p ~/.local/share/steel/cogs/helix-fcitx-focus/cogs
cp cogs/fcitx-focus.scm ~/.local/share/steel/cogs/helix-fcitx-focus/cogs/
```

## Behavior

- Leaving insert mode saves the current fcitx5 state and switches fcitx5 to
  inactive/English.
- Entering insert mode restores the saved active input method, if there was
  one.
- Focusing Helix in normal/select mode closes fcitx5.
- Focusing Helix while it is still in insert mode restores the saved input
  method instead of blindly closing it.
- When Helix gains focus, the plugin remembers the input method state that was
  active in the previous application.
- When Helix loses focus, the plugin restores that previous application input
  method state by default.
- SSH sessions and non-graphical sessions are ignored.

## License

Licensed under either of Apache License, Version 2.0 or MIT license at your
option.
