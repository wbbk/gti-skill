# GitHub Trending Intelligence

**GitHub 热门项目情报追踪 — v5 PR增强版**

自动抓取 GitHub 热门项目，按 Star 增速（⭐/天）排序，六维可信度+PR评分双保险，帮助发现真正有价值的项目。

---

## 功能特性

- 🔥 **Star 增速排序**：按每日增速排序，捕捉新晋爆款
- 🛡️ **六维+PR可信度**：综合评分过滤刷量项目
- 🤖 **AI 指数评分**：自动评估项目的 AI/Agent 相关度
- 📝 **中文项目介绍**：自动生成，降低阅读门槛
- ⏰ **定时推送**：可配置每天多次推送到飞书

---

## 防刷评分体系（v5）

```
综合评分 = 增速 × (可信度/100) × AI加成
可信度 = v4可信度×60% + PR可信度×40%
```

### v4 六维（占可信度60%）

| 维度 | 权重 | 防刷原理 |
|------|------|---------|
| Fork/Star比 | 40% | 需要真实开发者 fork，成本高 |
| 活跃 Issues | 20% | 需要真实讨论 |
| 协作者估算 | 20% | 多人协作更难伪造 |
| 仓库年龄 | 20% | 老项目更可信；新仓库增速×0.7 |

### PR 七维（占可信度40%）【新增】

| 维度 | 权重 | 防刷原理 |
|------|------|---------|
| 已合并PR数 | 50% | 合并PR需要真实代码贡献 |
| 近30天PR活跃度 | 50% | 持续贡献比一次性刷量更可信 |

**可信度等级**：
- 🟢 Green（≥60分）：正常项目
- 🟡 Yellow（30-60分）：需关注
- 🔴 Red（<30分）：疑似刷量

---

## 安装

```bash
# 安装 Skill
skillhub install github-trending-intelligence

# 或直接下载脚本
curl -fsSL https://raw.githubusercontent.com/wbbk/gti-skill/main/github-trending-intelligence.sh -o /usr/local/bin/gti
chmod +x /usr/local/bin/gti
```

## 配置

```bash
# GitHub Token（提高API限额）
export GITHUB_TOKEN="ghp_xxxx"

# 飞书 Webhook（可选）
export FEISHU_WEBHOOK="https://..."
```

## 使用

```bash
# Top 10 增速榜
gti --top 10

# OpenClaw 生态
gti --filter openclaw

# AI/Agent 项目
gti --filter ai

# JSON 格式
gti --top 20 --format json
```

## 输出字段

| 字段 | 说明 |
|------|------|
| 项目名 | GitHub 全名 |
| Star增速(⭐/天) | 每日增速 |
| 可信度 | 综合评分（v4+PR） |
| v4可信度 | 六维基础分 |
| PR可信度 | PR贡献分 |
| 已合并PRs | 合并PR总数 |
| 近30天PRs | 近期活跃PR |
| AI指数 | AI相关度 |

---

## 为什么 PR 很重要？

提交 PR 需要真实代码贡献，比 Star/Fork 更难伪造。一个项目有持续的 PR 合并，说明有真实开发者社区在参与。

---

## 常见问题

**Q: 为什么不只用 PR 评分？**
A: PR 数量受仓库类型影响大（文档项目PR多，CLI工具PR少），需要结合六维综合判断。

**Q: GitHub Token 怎么申请？**
A: GitHub → Settings → Developer settings → Personal access tokens → Generate new token（勾选 `public_repo`）
