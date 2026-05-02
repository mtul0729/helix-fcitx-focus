# helix-fcitx-focus

Steel plugin for Helix that keeps fcitx5 in English outside insert mode and
restores the previous active input method when entering insert mode.

This is useful for Chinese/Japanese/Korean input workflows where normal-mode
keys should stay ASCII, while insert mode should resume the input method you
were using before leaving insert mode.

## Requirements

- Helix built with Steel support from the `steel-event-system` branch.
- Steel focus event predicates from `mattwparas/helix#111`:
  `focus-gained-event?` and `focus-lost-event?`.
- fcitx5 running on the user session bus.

## Install

Build and install the native Steel module:

```sh
nix develop
cargo steel-lib
```

Copy the Scheme plugin into your Helix cogs directory:

```sh
mkdir -p ~/.config/helix/cogs
cp cogs/fcitx-focus.scm ~/.config/helix/cogs/
```

Then load the plugin from `~/.config/helix/init.scm`:

```scheme
(require "cogs/fcitx-focus.scm")
```

The repository also includes `cog.scm` metadata for future Steel/Forge package
experiments, but the copy-based install above is the tested path for now.

## Behavior

- Leaving insert mode saves the current fcitx5 state and switches fcitx5 to
  inactive/English.
- Entering insert mode restores the saved active input method, if there was
  one.
- Focusing Helix in normal/select mode closes fcitx5.
- Focusing Helix while it is still in insert mode restores the saved input
  method instead of blindly closing it.
- SSH sessions and non-graphical sessions are ignored.

## Notes

The fcitx5 integration is implemented as a Steel native module in Rust. It talks
to fcitx5 over DBus directly, so the Scheme side only maps Helix mode and focus
events to four small operations: save, close, save-and-close, and restore.

This plugin is intended as a real-world example for Steel terminal focus events:
terminal focus events complement `on-mode-switch`, because changing windows does
not necessarily change Helix's editor mode.

## License

Licensed under either of Apache License, Version 2.0 or MIT license at your
option.
