# helix-fcitx-focus

[English](README.md)

这是一个 Helix Steel 插件：在 insert mode 之外保持 fcitx5 为英文/非激活状态，并在进入 insert mode 时恢复之前使用的输入法。

它适合中文、日文、韩文等输入场景：normal mode 的按键应该保持 ASCII 命令输入，而 insert mode 应该恢复你离开 insert mode 前正在使用的输入法。

## 要求

- 使用支持 Steel 的 Helix，目前来自 `steel-event-system` 分支。
- 用户会话总线上正在运行 fcitx5。

## 使用 Forge 安装

通过 Forge 安装插件：

```sh
forge pkg install --git https://github.com/mtul0729/helix-fcitx-focus
```

然后在 `~/.config/helix/init.scm` 中加载插件：

```scheme
(require "helix-fcitx-focus/cogs/fcitx-focus.scm")
```

## NixOS / Home Manager

本仓库也提供 flake package 和 Home Manager module，方便声明式安装：

```nix
{
  inputs.helix-fcitx-focus.url = "github:mtul0729/helix-fcitx-focus";

  outputs =
    { helix-fcitx-focus, ... }:
    {
      # 在 Home Manager module 中：
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

## 开发

从本仓库进行本地开发：

```sh
nix develop
cargo steel-lib
mkdir -p ~/.local/share/steel/cogs/helix-fcitx-focus/cogs
cp cogs/fcitx-focus.scm ~/.local/share/steel/cogs/helix-fcitx-focus/cogs/
```

## 行为

- 离开 insert mode 时，保存当前 fcitx5 状态，并切换到非激活/英文状态。
- 进入 insert mode 时，如果之前保存过激活的输入法，则恢复它。
- Helix 在 normal/select mode 获得焦点时，关闭 fcitx5。
- Helix 仍处于 insert mode 并重新获得焦点时，恢复保存的输入法，而不是盲目关闭输入法。
- Helix 获得焦点时，插件会记住前一个应用中的输入法状态。
- Helix 失去焦点时，插件默认恢复前一个应用中的输入法状态。
- SSH 会话和非图形会话会被忽略。

## 许可证

本项目使用 Apache License, Version 2.0 或 MIT license 双许可证，你可以任选其一。
