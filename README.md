# GitHub Trending Intelligence

<div align="center">

**按 Star 增速排序的 GitHub 热门项目追踪 — 发现真正在爆发的新项目**

[简体中文](README.md) · [English](README_EN.md)

[![Stars](https://img.shields.io/github/stars/wbbk/github-trending-intelligence?style=flat-square)](https://github.com/wbbk/github-trending-intelligence)
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)

**🔥 特色**：按 ⭐/天 增速排序 | 🤖 AI 指数评分 | 📝 中文项目介绍 | ⏰ 定时推送

**[在线体验 →](https://wbbk.github.io/github-trending-intelligence/)**

</div>

---

## 🎯 为什么需要这个工具？

GitHub Trending 是找热门项目的首选，但**按总 Stars 排序存在严重问题**：

- OpenClaw 2025 年创建，已有 **32 万 Stars**，永远排在前面
- 新项目再有潜力，也被老项目压得看不到
- 真正在爆发的项目，你可能完全错过了

**增速排序**解决了这个问题：**每天新增 Stars 越多，排名越高**

```
传统 Trending：OpenClaw (32万⭐) → TypeScript (28万⭐) → ...
增速排序：  karpathy/autoresearch (3529⭐/天) → NVIDIA/NemoClaw (3007⭐/天) → ...
```

---

## ✨ 核心功能

| 功能 | 说明 |
|------|------|
| 🔥 **增速排序** | 按 Star 增速（⭐/天）排序，捕捉新晋爆款 |
| 🤖 **AI 指数** | 自动评估项目的 AI/Agent 相关度 |
| 🏷️ **分类体系** | OpenClaw生态 / AI-Agent / MCP-Tools / Python / 其他 |
| 📝 **中文介绍** | 自动生成中文简介，降低阅读门槛 |
| ⏰ **定时推送** | 可配置每天多次推送到飞书 |
| 📊 **多维评分** | AI指数 / Skill指数 / MCP指数 |

---

## 🚀 快速开始

### 安装

```bash
# 方式一：通过 OpenClaw SkillHub 安装
skillhub install github-trending-intelligence

# 方式二：直接下载脚本
curl -fsSL https://raw.githubusercontent.com/wbbk/github-trending-intelligence/main/github-trending-intelligence.sh -o /usr/local/bin/github-trending-intelligence
chmod +x /usr/local/bin/github-trending-intelligence
```

### 配置

```bash
# 可选：设置 GitHub Token（提高 API 限额）
export GITHUB_TOKEN="ghp_xxxxxxxxxxxx"

# 可选：设置飞书 Webhook（开启推送）
export FEISHU_WEBHOOK="https://open.feishu.cn/open-apis/bot/v2/hook/xxxxx"
```

> GitHub Token 申请：GitHub → Settings → Developer settings → Personal access tokens → Generate new token（勾选 `public_repo`）

### 使用

```bash
# 查看 Top 10 增速榜（Markdown 格式）
github-trending-intelligence --top 10

# 查看 OpenClaw 生态项目
github-trending-intelligence --filter openclaw

# 查看 AI/Agent 相关项目
github-trending-intelligence --filter ai

# 查看最近 7 天新建项目
github-trending-intelligence --filter new

# 输出 JSON 格式（程序调用）
github-trending-intelligence --top 20 --format json

# 指定 GitHub Token
github-trending-intelligence --token ghp_xxx --top 50
```

### OpenClaw 中使用

```
帮我追踪 GitHub 今日最热的 AI 项目，找出增速最快的前 10 个
```

---

## 📊 输出示例

```
📈 GitHub AI/开源热门 Top10（按增速排序）
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

#1  ⭐42.4k (3529⭐/天)  karpathy/autoresearch
    🏷️ [Python] 🤖 AI/Agent | AI:6 Skill:5 MCP:0
    Karpathy推出的AI科研Agent，自主规划研究实验
    🔗 https://github.com/karpathy/autoresearch

#2  ⭐9.0k (3007⭐/天)  NVIDIA/NemoClaw
    🏷️ [JavaScript] 🐟 OpenClaw生态
    NVIDIA推出的OpenClaw官方插件，一键部署和配置管理
    🔗 https://github.com/NVIDIA/NemoClaw

#3  ⭐323.5k (2837⭐/天)  openclaw/openclaw
    🏷️ [TypeScript] 🐟 OpenClaw生态
    开源本地优先的 AI Bot 生态系统
    🔗 https://github.com/openclaw/openclaw
```

---

## 🗂️ 数据维度说明

| 维度 | 说明 |
|------|------|
| **Star 增速(⭐/天)** | 总 Stars ÷ 创建天数，反映项目当前热度 |
| **AI 指数** | AI/Agent/LLM 相关关键词命中次数（越高越 AI 相关） |
| **Skill 指数** | 工具/CLI/Skill 封装潜力（越高越适合变现） |
| **MCP 指数** | MCP 协议相关度（越高越适合做 MCP Server） |

---

## 🎯 适用场景

| 人群 | 使用场景 |
|------|---------|
| 🛠️ **开发者** | 找热门工具做 Skill 封装变现 |
| 💰 **投资人/孵化器** | 发现下一个 OpenClaw 生态机会 |
| 📰 **自媒体** | 找 AI 赛道选题素材 |
| 🔬 **研究员** | 追踪 AI 技术最新进展 |
| 🚀 **创业者** | 找技术栈和方向参考 |

---

## 🏗️ 技术栈

- **语言**：Python 3
- **数据源**：GitHub API v3
- **无需 API Key**：基础功能完全免费（无 Token 60次/小时，有 Token 5000次/小时）

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

```bash
# Fork 本仓库
# 创建特性分支
git checkout -b feature/amazing-feature

# 提交改动
git commit -m "Add amazing feature"

# 推送分支
git push origin feature/amazing-feature

# 提交 Pull Request
```

---

## 📄 License

MIT License · Copyright (c) 2026 taizi-agent

---

<div align="center">

如果你觉得这个工具对你有帮助，欢迎 ⭐ Star 支持！

**[在线体验](https://wbbk.github.io/github-trending-intelligence/)** ·
**[提交 Issue](https://github.com/wbbk/github-trending-intelligence/issues)** ·
**[中文 Landing Page](https://wbbk.github.io/github-trending-intelligence/)**

</div>
