# AGENTS.md

> 本文件是**所有 AI 编码 agent 的入口约束**（Claude Code / Codex / Cursor / 自研脚本都读它）。
> 人也要读——它定义了"什么算完成"。

## 1. 项目一句话

跨境电商 ERP：Shopee 台湾 / TikTok 泰马 / Coupang 台湾 / momo 四个平台，模块化单体 + 独立 Worker。

## 2. 技术栈（锁定，不要擅自更换）

> 以根目录 `package.json` 的实际依赖为准；下表是"必须用"和"禁止用"的边界。

| 层 | 必须用 | 版本 | 禁止 |
|---|---|---|---|
| 运行时 | Node.js LTS | 22.x | 不要用 Bun/Deno |
| 语言 | TypeScript（strict） | 5.7+ | 不要写 `.js`，不要 `any`（例外要注释） |
| 后端框架 | NestJS | 11.x | 不要换 Express/Fastify/Koa 裸写 |
| 前端框架 | React | 18.x | **不要升 19**（AntD 5 需额外 patch） |
| UI 库 | **Ant Design 5 + ProComponents** | 5.x | **不要引入 MUI/Chakra/shadcn/Tailwind/Element** |
| 构建 | Vite | 7.x | 不要 Webpack |
| 请求/状态 | TanStack Query v5 + Zustand | — | 不要 Redux、不要 SWR |
| 表格 | TanStack Table v8（虚拟滚动） | — | — |
| 图表 | ECharts 5 | — | 不要 Chart.js/Recharts |
| 数据库 | PostgreSQL | 16.x | 不要 MySQL/SQLite（本地也不许） |
| ORM | Prisma（CRUD）+ Kysely（复杂查询） | — | 不要 TypeORM/Sequelize |
| 队列 | Redis 7 + BullMQ | — | 不要 Kafka/RabbitMQ |
| 包管理 | pnpm workspace | 9.x | 不要 npm/yarn |
| 图标 | `@ant-design/icons` | — | 不要引入其他图标库 |

> 例外：`eslint.config.mjs`、`vite.config.ts` 等工具配置文件不受"不要写 `.js`"限制。

### 2.1 UI 约定（写代码前先看）

1. **列表页一律 `ProTable`**，不要自己拼 `Table` + `Form` + 分页。
2. **表单一律 `ProForm` / `ModalForm` / `DrawerForm`**，不要用裸 `Form` 从头搭。
3. **布局用 `ProLayout`**，不要自己写侧边栏。
4. **主题**：`ConfigProvider` 开 `theme.algorithm = [compactAlgorithm]`，字号可切 12/13/14。
5. **样式**：优先用 AntD 的 `token` 和 `style`，**不要引入 Tailwind、styled-components、CSS Modules 之外的方案**；必须写 CSS 时用 `*.module.css`。
6. **国际化**：文案一律走 `i18next` 的 `t()`，**不允许硬编码中文**；至少 zh-CN / zh-TW。
7. **金额/时间展示**：用统一的 `<Money />`、`<DateTime />` 组件，不要在页面里手写 `toFixed`。
8. **打印**：面单由后端生成 PDF，前端只做预览与调起打印，不要用 CSS 打印。

## 3. 目录地图（先确认你该改哪块）

```
apps/api            HTTP 入口（Controller/Guard）
apps/worker         队列消费者（同步/回传/自动化）
apps/scheduler      定时任务
apps/web            React 管理台
packages/contracts  ★ 跨端契约（DTO/错误码/事件 schema）——改动需人工批准
packages/domain     纯领域（订单状态机/库存/成本），禁止 import 框架
packages/application 用例编排（事务边界）
packages/infrastructure 仓储/队列/存储/加密
packages/connectors 平台 SDK（core + shopee/tiktok/momo/coupang）
db/migrations       只增不改，序号向架构负责人申请
fixtures/           脱敏的平台响应样本（契约测试用）
docs/               方案文档与 ADR
```

## 4. 常用命令

```bash
pnpm install
pnpm typecheck     # 必须通过
pnpm lint          # 必须通过
pnpm test          # 必须通过
pnpm db:migrate    # 本地迁移
pnpm dev:api       # 启动 API
pnpm dev:web       # 启动前端
```

## 5. 硬性约束（违反即打回）

1. **不得修改已定稿的契约**（`packages/contracts/` 里已有的类型、错误码、事件）：需要改先提 Issue，人工确认后由契约负责人改。
   新增空包骨架或新文件不在此限。
2. **不得新增依赖**：确需新增，在 PR 描述里写"为什么、替代方案、体积影响"，人工批准。
3. **不得改动 `db/migrations/` 已有文件**：只能新增，序号找负责人分配。
4. **不得提交**：`.env`、真实买家数据、平台密钥、`node_modules`、构建产物。
5. **不得跨模块改文件**：一次 PR 只碰一个模块目录（跨模块改动要拆分）。
6. **不得"顺手重构"**：重构单独 PR，不和功能混在一起。
7. **不得手改生成代码**：OpenAPI 客户端、Prisma Client 由命令生成。

## 6. 领域约定

| 主题 | 约定 |
|---|---|
| 金额 | 整数最小单位 + 币种，禁止浮点；跨币种用有理数汇率 |
| 时间 | 存 UTC（`timestamptz`），展示按店铺时区 |
| 租户 | 每个查询必须带 `tenant_id`；仓储层强制注入 |
| 错误 | 业务失败返回 `Result`，程序错误才 throw；错误码见 `contracts/errors.ts` |
| 库存 | 只追加流水；余额是投影；预占独立表 |
| 幂等 | 所有外部写操作带 `idempotency_key` |

## 7. 完成任务的定义（DoD）

- [ ] `pnpm typecheck && pnpm lint && pnpm test` 全绿
- [ ] 新增/修改的逻辑有对应单测（领域层覆盖率 > 80%）
- [ ] 涉及外部接口的，附脱敏 fixture + 契约测试
- [ ] 涉及数据库的，有迁移 + 回滚说明
- [ ] PR 描述填完模板（改了什么、风险、怎么回滚）
- [ ] 改动行数 ≤ 400（超过请拆分）

## 8. 上下文从哪来

1. `docs/00-结论与方案总览.md` — 先搞清做什么
2. `docs/03-技术架构与基础框架.md` — 分层与连接器约定
3. `docs/04-数据模型与核心流程.md` — 表与状态机
4. `fixtures/` — 平台真实报文（唯一可信的字段来源）
5. `docs/adr/` — 已定型的决策，别推翻

## 9. 卡住怎么办

- 平台字段不确定 → **不要猜**，在 PR 里标 `TODO(verify-with-fixture)` 并说明缺什么
- 需求不清 → 提 Issue，不要自行发挥
- 冲突无法解决 → 停止改动，输出"冲突点 + 两个方案 + 建议"，交人工决策

## 10. 沟通

- 一个 PR 只解决一个 Issue，描述里写 `Closes #123`
- 长任务先输出计划再动手，计划被批准后再写代码
- 不要在同一分支上并行改多个模块
