# ERP

跨境电商 ERP：Shopee 台湾 / TikTok 泰马 / Coupang 台湾 / momo 四个平台，模块化单体 + 独立 Worker。

> 开发约束（技术栈、目录、硬性规则、完成定义）全部在 **[AGENTS.md](./AGENTS.md)**，写代码前先读。

## 环境要求

| 工具 | 版本 |
|---|---|
| Node.js | 22.x（仓库根有 `.node-version`，fnm / nvm 可自动切换） |
| pnpm | 9.x（由 `package.json` 的 `packageManager` 锁定，`corepack enable` 即可） |
| Docker | 本地 PostgreSQL 16 + Redis 7 |

## 快速开始

```bash
cp .env.example .env        # 按需修改；.env 不进 git
docker compose up -d        # 启动 postgres / redis（带 healthcheck）
pnpm install
pnpm db:migrate             # 执行数据库迁移
pnpm dev:api                # http://127.0.0.1:3000/health
pnpm dev:web                # http://127.0.0.1:5173
```

## 常用命令

| 命令 | 作用 |
|---|---|
| `pnpm typecheck` | 全部包类型检查 |
| `pnpm lint` | ESLint |
| `pnpm test` | Vitest（根级单次运行） |
| `pnpm build` | 全部包构建 |
| `pnpm db:migrate` / `db:migrate:down` | 执行 / 回滚迁移（作用于 `DATABASE_URL`） |
| `pnpm db:migrate:check` | 在临时库上验证迁移可 up/down，不碰主库 |

## 目录

```
apps/api        NestJS HTTP 入口
apps/web        React 管理台（Vite + Ant Design）
packages/*      contracts / domain / application / infrastructure / connectors
db/migrations   SQL 迁移（只增不改）
.github/        CI、PR 模板、Issue 模板、CODEOWNERS、Dependabot
```

## 协作约定

- 分支：`feat/*`、`fix/*`、`chore/*`、`hotfix/*`
- 提交：Conventional Commits（`feat(scope): ...`）
- PR：一个任务一个 PR，≤ 400 行，填完 PR 模板，CI（`verify`）绿才可合
- `main` 受保护：必须走 PR，至少 1 个 approve，必须通过 `verify`
