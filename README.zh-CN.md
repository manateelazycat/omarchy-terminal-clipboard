# Omarchy Terminal Clipboard

简体中文 | [English](README.md)

![Omarchy Terminal Clipboard](preview.png)

一个 [Omarchy](https://omarchy.org/) 插件：针对当前窗口发送合适的复制和粘贴按键组合，让 `Super+C` 和 `Super+V` 在普通应用、终端、Lazycat Terminal 和 LightOS 中都能一致工作。

## 安装

```bash
omarchy plugin add https://github.com/manateelazycat/omarchy-terminal-clipboard.git --enable
```

无需额外配置。

## 行为

| 当前窗口 | `Super+C` 发送 | `Super+V` 发送 |
| --- | --- | --- |
| Lazycat Terminal（`class = com.lazycat.terminal`） | `Ctrl+Shift+C` | `Ctrl+Shift+V` |
| LightOS（`initial_title` 以 `cloud.lazycat.lightos` 开头，或 `lzc-client-desktop` 窗口标题包含 `LightOS WebShell`） | `Ctrl+Shift+C` | `Ctrl+Shift+V` |
| Omarchy 识别的终端 | `Ctrl+Insert` | `Shift+Insert` |
| 其他应用 | `Ctrl+C` | `Ctrl+V` |

LightOS 匹配同时覆盖域名式标题，以及初始标题为 `LightOS container Manager` 并带有用户专属后缀的 LightOS WebShell 窗口。Hyprland 配置重新加载后，运行时快捷键会自动重新应用。

## 状态

```bash
omarchy-shell io.github.manateelazycat.terminal-clipboard status
```

## 卸载

```bash
omarchy plugin remove io.github.manateelazycat.terminal-clipboard
```

插件卸载后会恢复 Omarchy 默认的通用剪贴板快捷键。

## 依赖

- 带有 Quickshell 插件系统的 Omarchy
- 支持 Lua 配置的 Hyprland

## 开发

```bash
npm test
omarchy plugin validate .
qmllint -I "$OMARCHY_PATH/shell" Service.qml
```

## 协议

仅按 GNU General Public License v3.0 发布。详见 [LICENSE](LICENSE)。
