# mhswitch

面向 AI CLI 与多机场场景的 Mihomo 管理脚本。

`mhswitch` 使用一个 Bash 脚本完成 Mihomo 安装、机场订阅管理、配置生成、节点故障切换、OpenAI/ChatGPT 可达性检测，以及 Claude、Codex 和浏览器的分流控制。

> 当前主要面向 Linux。脚本只管理 Mihomo 和生成规则，不会自动修改桌面系统代理、Shell 代理变量或防火墙。

## 功能

- 自动检测 Mihomo；缺失时从官方 GitHub Releases 安装最新稳定版
- 首次启动时提示输入机场订阅链接
- 管理多个 Clash/Mihomo YAML 订阅，并自动识别机场名称
- 自动生成统一的 Mihomo 配置和多机场策略组
- OpenAI/Codex 默认优先美国节点，美国节点不可用时可回退到其他地区
- Claude 默认固定美国地区，在多个美国节点间故障切换
- 支持单机场自动组、手动选点组和跨机场故障切换组
- 检测普通网络延迟以及 OpenAI/ChatGPT 网站可达性
- 提供键盘交互式终端控制面板
- 主菜单实时显示服务、代理模式、机场数量和 OpenAI/Codex 当前策略
- 支持方向键、`k`/`j` 和数字键快速选择；中断性操作执行前确认
- 国内地址、生信数据源、Conda 镜像和 Git 托管站点默认直连
- 浏览器流量按规则选择代理，未匹配的其他程序默认直连

## 默认路由策略

| 流量 | 默认策略 |
| --- | --- |
| Codex CLI | `OpenAI` 组，美国节点优先并提供全地区兜底 |
| Claude CLI | `Claude` 组，美国节点故障切换 |
| ChatGPT/OpenAI 域名 | 强制进入 `OpenAI` 组 |
| 常见浏览器 | 国内和私有地址直连，其余流量进入 `默认代理` |
| GitHub、GitLab、Bitbucket | 直连 |
| NCBI、CNCB 等生信数据源 | 直连 |
| Conda/Anaconda 及常见镜像 | 直连 |
| 其他未匹配程序 | 直连 |

默认 AI 地区是美国，可通过环境变量改为其他地区。

## 工作方式

`mhswitch` 根据机场订阅生成以下主要策略：

```text
OpenAI/Codex
  -> 美国节点故障切换
  -> 全地区 OpenAI 可用节点
  -> 普通可用节点
  -> DIRECT

Claude
  -> 美国节点故障切换

默认代理
  -> 所有机场节点故障切换
  -> DIRECT
  -> 单机场自动/手动组
```

这里的“故障切换”使用 Mihomo `fallback` 策略：定时检查当前节点，只在节点超时或不可用时切换。它不会因为另一个节点延迟更低而频繁换线。

默认检查间隔为 300 秒，普通节点超时阈值为 5000 毫秒，OpenAI 检测超时为 10000 毫秒。

## 环境要求

- Linux
- Bash 4.0 或更高版本
- `curl`
- `python3`
- `gzip`，仅在自动安装 Mihomo 时需要

Mihomo 可以预先安装，也可以交给 `mhswitch` 自动安装。自动安装支持常见 Linux 架构，包括 amd64、arm64、armv5/6/7、386、MIPS、ppc64le、riscv64、s390x 和 loong64。

## 安装

### 使用 Git 克隆

```bash
git clone https://github.com/Ch3mmy/mhswitch.git
cd mhswitch
install -Dm755 mhswitch "$HOME/.local/bin/mhswitch"
```

### 直接下载脚本

```bash
mkdir -p "$HOME/.local/bin"
curl -fL https://raw.githubusercontent.com/Ch3mmy/mhswitch/main/mhswitch \
  -o "$HOME/.local/bin/mhswitch"
chmod +x "$HOME/.local/bin/mhswitch"
```

确保 `~/.local/bin` 已加入 `PATH`：

```bash
export PATH="$HOME/.local/bin:$PATH"
```

如需永久生效，请将上面一行加入 `~/.bashrc` 或当前 Shell 对应的配置文件。

## 快速开始

运行：

```bash
mhswitch start
```

首次启动时，脚本会：

1. 检查 Mihomo 是否存在并能够运行。
2. 如果缺失，从 Mihomo 官方稳定版发布页下载适合当前架构的程序。
3. 在尚未配置机场时提示输入订阅链接。
4. 下载并解析订阅，生成 `~/.config/mihomo/config.yaml`。
5. 在后台启动 Mihomo。

也可以分步执行：

```bash
mhswitch install
mhswitch add "https://example.com/your-subscription" "我的机场"
mhswitch start
```

启动后默认监听：

| 用途 | 地址 |
| --- | --- |
| HTTP/SOCKS mixed port | `127.0.0.1:17890` |
| Mihomo controller | `http://127.0.0.1:9090` |

脚本不会自动设置系统代理。需要根据桌面环境配置系统代理，或者在需要的终端中设置：

```bash
export HTTP_PROXY=http://127.0.0.1:17890
export HTTPS_PROXY=http://127.0.0.1:17890
export ALL_PROXY=socks5://127.0.0.1:17890
```

## 交互控制面板

在交互式终端中直接运行：

```bash
mhswitch
```

也可以显式打开：

```bash
mhswitch panel
```

使用方向键或 `k`/`j` 移动，按 `1`-`9` 快速选择对应项目，按 Enter 确认，按 Esc 或 `q` 返回。主菜单直接显示 Mihomo 服务状态、当前模式、机场数量和 OpenAI/Codex 策略。停止、重启或切断现有连接前会再次确认。

订阅输入会先检查是否为 HTTP(S) URL、`file://` URL 或已有本地文件，格式不正确时会留在输入界面继续提示。

## 命令参考

### 机场管理

| 命令 | 说明 |
| --- | --- |
| `mhswitch add <url> [name]` | 添加机场；名称可省略并自动识别 |
| `mhswitch remove <name>` | 删除机场 |
| `mhswitch update` | 更新全部机场订阅 |
| `mhswitch list` | 查看服务、策略和机场状态 |
| `mhswitch nodes [all\|机场名]` | 查看全部或指定机场的节点 |

订阅必须是包含 `proxies:` 字段的 Clash/Mihomo YAML。相同名称或相同订阅 URL 再次添加时，会覆盖更新原机场。

### Mihomo 服务

| 命令 | 说明 |
| --- | --- |
| `mhswitch install` | 检查并安装 Mihomo 官方稳定版 |
| `mhswitch start` | 生成配置并后台启动；缺失时自动安装 |
| `mhswitch stop` | 停止 Mihomo |
| `mhswitch restart` | 重新生成配置并重启 |
| `mhswitch reload` | 重新生成并热重载配置，不更新订阅 |
| `mhswitch status` | 查看运行状态和当前策略 |
| `mhswitch log` | 持续查看 Mihomo 日志 |

### OpenAI 和 Codex

`codex` 是 `openai` 命令的别名。

| 命令 | 说明 |
| --- | --- |
| `mhswitch openai` | 交互选择机场和规则；非交互环境使用 `best` |
| `mhswitch openai best` | 美国节点优先，失败后回退到全地区可用节点 |
| `mhswitch openai strict` | 只使用美国节点，不允许地区兜底 |
| `mhswitch openai global` | 使用所有地区中可访问 OpenAI 的节点 |
| `mhswitch openai direct` | OpenAI 流量直连 |
| `mhswitch openai <机场名>` | 固定该机场的美国节点组 |
| `mhswitch openai <机场名> auto` | 该机场内美国优先、全地区兜底 |
| `mhswitch openai <机场名> global` | 使用该机场全部地区的 OpenAI 可用节点 |

推荐日常使用：

```bash
mhswitch openai best
```

### Claude

| 命令 | 说明 |
| --- | --- |
| `mhswitch claude best` | 在所有机场的美国节点中故障切换 |
| `mhswitch claude <机场名>` | 固定指定机场的美国节点组 |

### 普通代理和模式

| 命令 | 说明 |
| --- | --- |
| `mhswitch proxy <机场名> auto` | 使用指定机场的自动故障切换组 |
| `mhswitch proxy <机场名> manual` | 使用指定机场的手动节点组 |
| `mhswitch git direct` | 将 Git Clone 策略设为直连 |
| `mhswitch git proxy` | 将 Git Clone 策略设为默认代理 |
| `mhswitch git best` | 将 Git Clone 策略设为最优节点组 |
| `mhswitch mode rule` | 使用规则模式 |
| `mhswitch mode global` | 使用全局模式 |
| `mhswitch mode direct` | 使用直连模式 |
| `mhswitch flush` | 切断当前连接，使新策略立即用于后续连接 |

生成的规则会将 GitHub、GitLab 和 Bitbucket 域名固定为直连，因此 `mhswitch git` 主要用于兼容和手动策略查看；在默认 `rule` 模式下，域名直连规则优先。

## 节点检测

### 普通延迟测试

```bash
mhswitch delay all
mhswitch delay "机场名"
mhswitch delay "策略组名" "https://www.gstatic.com/generate_204" 5000 12
```

参数依次为目标、测试 URL、超时时间（毫秒）和并发数。测试只显示结果，不会改变自动故障切换顺序。

### OpenAI/ChatGPT 可达性测试

```bash
mhswitch openai-test
mhswitch openai-test strict
mhswitch openai-test global
mhswitch openai-test each
mhswitch openai-test "机场名"
```

默认测试地址：

```text
https://chatgpt.com/cdn-cgi/trace
```

这个检查只能证明节点能够访问 ChatGPT/OpenAI 相关域名，不代表：

- OpenAI API Key 有效
- ChatGPT 账号拥有特定套餐或功能
- Codex 的 WebSocket、MCP 或长连接一定稳定
- 节点不会在后续被限流或改变出口地区

对 Codex 稳定性要求较高时，建议在通过 `openai-test` 后，再运行一次真实的 Codex 请求验证。

## 自动切换条件

默认配置：

| 参数 | 默认值 |
| --- | --- |
| 健康检查间隔 | 300 秒 |
| 普通节点超时 | 5000 毫秒 |
| OpenAI 节点超时 | 10000 毫秒 |
| 懒检查 | 关闭，即定时主动检查 |

当前节点正常时，即使其他节点更快，也不会自动切换。只有当前节点超时或不可用时，Mihomo 才会按候选顺序切换。

## 环境变量

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `MIHOMO_HOME` | `~/.config/mihomo` | 配置和状态目录 |
| `MIHOMO_BIN` | 自动查找 | 指定 Mihomo 可执行文件 |
| `MIHOMO_CONTROLLER` | `http://127.0.0.1:9090` | Mihomo 控制器地址 |
| `MIHOMO_SECRET` | 空 | 控制器鉴权密钥 |
| `MHSWITCH_MIHOMO_INSTALL_DIR` | `~/.local/bin` | Mihomo 自动安装目录 |
| `MHSWITCH_MIHOMO_VERSION` | 最新稳定版 | 指定安装版本，例如 `v1.19.29` |
| `MHSWITCH_MIHOMO_RELEASE_LATEST_URL` | Mihomo GitHub latest 页面 | 覆盖稳定版发现地址，主要用于镜像源 |
| `MHSWITCH_MIHOMO_RELEASE_BASE_URL` | Mihomo GitHub 下载目录 | 覆盖发布文件基础地址 |
| `MHSWITCH_MIHOMO_DOWNLOAD_URL` | 空 | 直接指定 `.gz` 安装包并跳过版本发现 |
| `MHSWITCH_AI_REGION_NAME` | `美国` | AI 固定地区的显示名称 |
| `MHSWITCH_AI_REGION_FILTER` | 美国节点正则 | AI 地区节点过滤规则 |
| `MHSWITCH_AI_EXCLUDE_FILTER` | `DRT\|MIX`，忽略大小写 | OpenAI 节点额外排除规则 |
| `MHSWITCH_OPENAI_TEST_URL` | `https://chatgpt.com/cdn-cgi/trace` | OpenAI 健康检查地址 |
| `MHSWITCH_OPENAI_TEST_TIMEOUT` | `10000` | OpenAI 检查超时，毫秒 |
| `MHSWITCH_CLAUDE_TEST_URL` | `https://claude.ai` | Claude 健康检查地址 |
| `MHSWITCH_DELAY_URL` | Google `generate_204` | 手动测速地址 |
| `MHSWITCH_DELAY_TIMEOUT` | `5000` | 手动测速超时，毫秒 |
| `MHSWITCH_DELAY_JOBS` | `12` | 手动测速并发数 |
| `MHSWITCH_FAILOVER_INTERVAL` | `300` | 故障检查间隔，秒 |
| `MHSWITCH_FAILOVER_TIMEOUT` | `5000` | 故障超时，毫秒 |
| `MHSWITCH_FAILOVER_LAZY` | `false` | 是否使用懒检查 |
| `MHSWITCH_GIT_PROXY_DEFAULT` | `direct` | Git Clone 策略组默认选项 |
| `MHSWITCH_GIT_GROUP_NAME` | `Git Clone` | Git Clone 策略组名称 |
| `MHSWITCH_NO_EMOJI` | 空 | 设为 `1` 时禁用命令行 emoji |

例如，将 AI 固定地区改为日本：

```bash
export MHSWITCH_AI_REGION_NAME="日本"
export MHSWITCH_AI_REGION_FILTER='(?i)(🇯🇵|日本|JP|Japan|Tokyo|Osaka)'
mhswitch restart
```

关闭默认的 DRT/MIX 节点排除：

```bash
export MHSWITCH_AI_EXCLUDE_FILTER=''
mhswitch restart
```

## 文件位置

默认情况下：

| 文件 | 用途 |
| --- | --- |
| `~/.local/bin/mhswitch` | mhswitch 脚本 |
| `~/.local/bin/mihomo` | 自动安装的 Mihomo |
| `~/.config/mihomo/config.yaml` | 自动生成的 Mihomo 配置 |
| `~/.config/mihomo/mhswitch-state.json` | 机场名称、订阅 URL 和排除规则 |
| `~/.config/mihomo/providers/` | 下载和解析后的订阅文件 |
| `~/.config/mihomo/mihomo.log` | Mihomo 后台日志 |
| `~/.config/mihomo/mihomo.pid` | 后台进程 PID |

不要手动长期修改生成的 `config.yaml`；运行 `start`、`restart`、`reload`、`add` 或 `remove` 后，文件会重新生成。需要改变生成逻辑时，应修改脚本或使用环境变量。

## 常见问题

### `未找到 mihomo` 或 Mihomo 无法运行

```bash
mhswitch install
```

自动安装目前仅支持 Linux。也可以自行安装 Mihomo，并通过 `MIHOMO_BIN` 指定路径。

### 订阅下载失败

脚本默认让订阅下载绕过系统代理并直接连接。请确认订阅 URL 可直连、没有过期，并返回包含 `proxies:` 的 Clash/Mihomo YAML，而不是网页、登录页面或其他格式。

### `读取策略组失败` 或 HTTP 404

通常表示当前运行中的 Mihomo 仍在使用旧配置。执行：

```bash
mhswitch reload
```

如果仍然失败：

```bash
mhswitch restart
mhswitch status
```

### `openai-test` 通过，但 Codex 仍不稳定

`cdn-cgi/trace` 是轻量可达性测试，不覆盖登录、WebSocket、MCP 和长时间流式请求。可以增加超时时间、更换节点，或使用更严格的检测地址：

```bash
export MHSWITCH_OPENAI_TEST_URL="https://chatgpt.com/backend-api/"
export MHSWITCH_OPENAI_TEST_TIMEOUT=15000
mhswitch restart
mhswitch openai-test each
```

严格地址可能将“浏览器可用但 Codex 后端不稳定”的节点判定为失败，这是预期行为。

### 添加机场后没有美国节点

检查节点名称是否包含美国、US、USA、America 等可被默认正则识别的文本：

```bash
mhswitch nodes "机场名"
```

机场使用特殊命名时，请自定义 `MHSWITCH_AI_REGION_FILTER`。

### 端口被占用

默认使用 `17890` 和 `9090`。检查是否已有 Mihomo 或其他代理程序运行：

```bash
mhswitch status
mhswitch log
```

当前版本尚未提供端口环境变量；如需修改端口，需要调整脚本中的配置生成部分。

## 安全提示

- 订阅 URL 通常包含访问凭据，不要提交到 Git 仓库、日志或公开聊天中。
- 订阅 URL 会保存在 `~/.config/mihomo/mhswitch-state.json`。
- 建议限制状态目录权限：

```bash
chmod 700 "$HOME/.config/mihomo"
chmod 600 "$HOME/.config/mihomo/mhswitch-state.json"
```

- Mihomo 控制器默认只监听 `127.0.0.1`，不要在没有鉴权的情况下暴露到局域网或公网。
- 从网络下载脚本后，建议先查看内容，再授予执行权限。

## 卸载

先停止服务：

```bash
mhswitch stop
```

删除脚本和自动安装的 Mihomo：

```bash
rm -f "$HOME/.local/bin/mhswitch" "$HOME/.local/bin/mihomo"
```

如确认不再需要机场状态和订阅缓存，再删除配置目录：

```bash
rm -rf "$HOME/.config/mihomo"
```

最后一个操作会永久删除本地订阅信息和配置，请先确认目录中没有需要保留的内容。

## 相关项目

- [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo) - Mihomo 核心
- [Mihomo Wiki](https://wiki.metacubex.one/) - 配置与使用文档

## 贡献

欢迎提交 Issue 或 Pull Request。提交修改前，请至少运行：

```bash
bash -n mhswitch
./mhswitch help
bash tests/ui_interaction_test.sh
```

报告问题时，请提供操作系统、CPU 架构、Mihomo 版本、执行的命令和脱敏后的错误信息。请勿公开订阅 URL、控制器密钥或节点凭据。
