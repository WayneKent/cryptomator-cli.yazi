[English](README.md) | [中文](README.zh-CN.md)

# cryptomator-cli.yazi

Yazi 文件管理器的 Cryptomator 保险库挂载、卸载插件

## 功能特性

- 🔍 自动检测当前目录或预览目录中的 Cryptomator 保险库（`.cryptomator` 文件）
- ⌨️ 交互式密码输入挂载加密保险库
- 🔓 安全的保险库卸载功能
- ⚙️ 可配置的挂载点位置
- 💬 操作状态通知反馈

## 📦 安装方法

### 方法1：使用 ya 包管理器

```bash
ya pkg add WayneKent/cryptomator-cli
```

### 方法2：手动安装

1. 从 GitHub 克隆仓库：
    ```bash
    git clone https://github.com/WayneKent/cryptomator-cli.yazi.git
    ```
2. 将插件复制到 Yazi 插件目录：
    ```bash
    cp -r cryptomator-cli.yazi ~/.config/yazi/plugins/
    ```
3. 确保系统已安装 `cryptomator-cli` 命令

## 🛠️ 使用方法

### 挂载保险库

1. 进入包含 `.cryptomator` 文件的目录，或
2. 在其上级目录中将光标移动到目标目录上
3. 按下 `mc` 快捷键
4. 输入保险库密码

### 卸载保险库

1. 进入已挂载的保险库目录，或
2. 在其上级目录中将光标移动到目标目录上
3. 按下 `uc` 快捷键

## ⌨️ 必须配置键位映射

在 `~/.config/yazi/keymap.toml` 中添加以下配置之一：

```toml
[mgr]
prepend_keymap = [
{ on = ["m", "c"], run = "plugin cryptomator-cli -- --mount", desc = "挂载 Cryptomator 保险库" },
{ on = ["u", "c"], run = "plugin cryptomator-cli -- --umount", desc = "卸载 Cryptomator 保险库" },
]
```

或

```toml
[[mgr.prepend_keymap]]
on = ["m", "c"]
run = "plugin cryptomator-cli -- --mount"
desc = "挂载 Cryptomator 保险库"

[[mgr.prepend_keymap]]
on = ["u", "c"]
run = "plugin cryptomator-cli -- --umount"
desc = "卸载 Cryptomator 保险库"
```

## ⚙️ 配置

### 挂载目录配置

在 `~/.config/yazi/init.lua` 中添加：

```lua
require('cryptomator-cli'):setup({
    mount_parent = '~/mnt' --default
})
```

## 依赖

- [Cryptomator CLI](https://github.com/cryptomator/cli)
- FUSE 文件系统支持

## 常见问题

**Q: 挂载失败怎么办？**  
✅ 检查：

1. 已安装 cryptomator-cli
2. 有 FUSE 支持
3. 密码正确

**Q: 如何修改默认挂载位置？**  
⚙️ 编辑 init.lua 中的 `mount_parent` 配置

## 许可证

本项目采用 [MIT 许可证](LICENSE) 开源。

## 🙏 致谢

- 🦆 [Yazi](https://github.com/sxyazi/yazi) - 强大的终端文件管理器
- 🔐 [Cryptomator CLI](https://github.com/cryptomator/cli) - 加密存储挂载工具
