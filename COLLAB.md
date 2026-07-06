# COLLAB.md — 三方文件协作规范

> 项目: [Dual-Track AI Architecture (DTA)](./README.md)
> 参与方: 悟色 · 大聪明 · 聪明CC
> Owner: 大聪明（GitHub 唯一 push 权限持有者）
> 生效日期: 2026-07-06

---

## 唯一路径规则

**所有项目文件只有一个正确落点：Coze 群项目文件夹 `/dual-track-ai-architecture/`。**

- ✅ **正确**：`coze agent file upload --project-dir /dual-track-ai-architecture --local-file-path ...`
- ❌ **错误**：`computer://三方文件/xxx.md`（这是聊天附件，只有 UI 能看到，其他 agent **拉不到**）
- ❌ **错误**：私聊、邮件、群文件外的任何位置

> **前车之鉴**：v0.4 时聪明CC 用 `computer://三方文件/HANDOFF-v0.4.md` 交付，大聪明 拉不到原文，只能根据消息里披露的部分数据手工合并——**损失了 patch 里未在消息中披露的其它修正**。这种错不能再犯。

---

## ⚠️ Agent 间协作机制（2026-07-06 更正）

**Coze 群聊里 agent → agent 的 @ 直接触达不生效**。所有 @ 只有主人（人类）能触发跨 agent 通知。因此项目采用**文件邮箱 + 主人路由**机制：

### 目录约定

```
/dual-track-ai-architecture/
├── INBOX/                                 ← 待处理任务/消息
│   ├── to-wuse-YYYYMMDD-HHMM-主题.md      ← 给悟色的
│   ├── to-cc-YYYYMMDD-HHMM-主题.md         ← 给聪明CC 的
│   └── to-dcm-YYYYMMDD-HHMM-主题.md        ← 给大聪明的
└── OUTBOX/                                 ← 完成后归档
    └── from-A-YYYYMMDD-HHMM-主题.md
```

### 消息文件模板

```markdown
# to-<recipient> <日期时间> <主题>

**From**: <发件人 agent>
**To**: <收件人 agent>
**Priority**: P0 | P1 | P2
**Deadline**: <YYYY-MM-DD or ASAP>
**Related**: <相关文件/commit>

## 任务
<一句话说清楚要做什么>

## 交付要求
- <具体产物 1>
- <具体产物 2>

## 上下文
<必要的背景，不要太长>

## 完成后
把结果写到 `OUTBOX/from-<你>-<日期时间>-<主题>.md`
然后请主人在群里 @ <发件人>
```

### 流程

```
1. Agent A 写 INBOX/to-B-<主题>.md 上传项目文件夹
2. Agent A 在群里发一句话（不要长回复）：
   "@主人 请转告 B：看 INBOX/to-B-<主题>.md"
3. 主人在群里 @ B："看 INBOX/to-B-<主题>.md"（复制路径即可）
4. B 处理完写 OUTBOX/from-B-<主题>.md
5. B 在群里发一句话："@主人 请转告 A：看 OUTBOX/from-B-<主题>.md"
```

**主人成本**：每次路由只需复制一行路径 + @ 对应 agent，不用读内容细节。

### 反面示范

- ❌ 群里直接长篇 @ 另一个 agent（对方收不到通知，你不知道）
- ❌ 期待对方主动来读你的 push（她们不会轮询 GitHub）
- ❌ 主人不在时死等——**要在文件邮箱里留任务，主人上线后一次性路由**

---

## 三种交付格式

**根据修改幅度选一种：**

| 场景 | 格式 | 落点 | 交给谁 |
|---|---|---|---|
| **新增/大改整个文件** | 完整 `.md` 文件 | `/dual-track-ai-architecture/文件名.md` | 大聪明 review 后合入 GitHub |
| **对现有文件的小改（<50 行）** | `.patch` 文件（`git diff` 或 `git format-patch` 生成） | `/dual-track-ai-architecture/patches/YYYYMMDD-作者-描述.patch` | 大聪明 `git apply` 后 push |
| **数据点/证据补充** | 群消息 markdown 表格或引用列表 | 群里直接发 | 大聪明 手工合入相关文件 |

**约定**：
- 补丁必须能 `git apply` 干净——**上传前请本地 dry-run 一次**：`git apply --check your.patch`
- 补丁如果覆盖多文件，用 `git format-patch -1` 保留 commit message
- 单条数据补充**不必用 patch**，群里发 markdown 表格更快

---

## 命名规范

| 类型 | 命名格式 | 举例 |
|---|---|---|
| 交接文档 | `HANDOFF-vX.Y.md` | `HANDOFF-v0.5.md` |
| 补丁 | `patches/YYYYMMDD-作者-描述.patch` | `patches/20260707-cc-datasheet-fixes.patch` |
| 新章节 / 新文件 | 语义化英文，不用中文 | `INDUSTRY-PULSE.md`, `counterexamples/C1.md` |
| 临时草稿 | `drafts/YYYYMMDD-作者-主题.md` | `drafts/20260707-wuse-agentic-counterexample.md` |

---

## 数据可信度规则（不可协商）

**这是学术项目，数据是命根子。**

- 所有数值必须能追溯到官方 datasheet / whitepaper / 一手报道
- 找不到官方来源 → **明确标注"官方文档暂缺 / 二手估算 / TODO"**，不要蒙估算
- 引用格式：`[来源](URL)` + 一句话 context

**红线**：
- ❌ 用记忆里的数字冒充官方数据
- ❌ 用 AI 生成的估算冒充实测
- ❌ 复制他人内容不给引用

---

## 交付 → Review → 合入 流程

```
[任意 agent] 上传文件到 /dual-track-ai-architecture/ 或发群消息
      ↓
[任意 agent] @大聪明 通知需要合入
      ↓
[大聪明] review 数据可信度 + 格式正确性
      ↓
      成功 → git apply/copy → push GitHub → 群里回执 + Release note
      失败 → 群里反馈问题 → 作者修 → 重传
```

**Review 要点**：
1. 数据来源是否有官方引用？
2. 是否与现有文件冲突/重复？
3. 补丁是否 `git apply --check` 通过？
4. 分工是否越界？（比如聪明CC 不该改 paper.md 主体）

---

## 分工边界（v0.3.1 已定）

- **悟色**：`paper.md`（中文主稿）、`validation_plan.md`、H1-H3 产业证据链、Tier 4 反例场景枚举
- **大聪明**：`paper.en.md`（英文扩展）、`README.md` + `CHANGELOG.md` + `LICENSE` 维护、GitHub push、Tier 2 Mac 本机 benchmark
- **聪明CC**：`EVIDENCE.md` datasheet 复核与拓展、`counterexamples/` 量化、`INDUSTRY-PULSE.md`、学术文献综述

**越界前先 @ 群通气**。三方论证有分歧时主人拍板。

---

## 快速核对清单（交付前自检）

- [ ] 文件放到了 `/dual-track-ai-architecture/` 项目文件夹，不是 `computer://` 前缀
- [ ] 命名符合规范
- [ ] 所有数值都有引用来源，或明确标 TODO
- [ ] 如果是 `.patch`，本地 `git apply --check` 通过
- [ ] 在群里 @大聪明 并简述改了什么、为什么

---

## 常用命令（速查）

```bash
# 从群项目文件夹拉文件（Coze CLI）
coze agent file download \
  --project-id 7659282950676316462 \
  --project-file-path "/dual-track-ai-architecture/HANDOFF-v0.5.md"

# 上传文件到群项目文件夹
coze agent file upload \
  --project-id 7659282950676316462 \
  --local-file-path ./HANDOFF-v0.5.md \
  --project-dir /dual-track-ai-architecture

# 列出项目文件夹内容
coze agent file list \
  --project-id 7659282950676316462 \
  --project-dir /dual-track-ai-architecture --depth 3

# 生成补丁
cd ~/Documents/GitHub/dual-track-ai-architecture
git diff > /tmp/my-changes.patch
# 或带 commit message 的：
git format-patch -1 HEAD -o /tmp/patches/

# 校验补丁（合入前必做）
git apply --check /tmp/my-changes.patch
```

---

*Version: v1.0 · 2026-07-06 · 大聪明发起，三方共同遵守*
