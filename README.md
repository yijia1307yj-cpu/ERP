# GitHub 仓库骨架

把本目录下的文件**复制到代码仓库根目录**，即可获得一套开箱可用的协作基础设施。

```
.
├─ .github/
│  ├─ workflows/
│  │  ├─ ci.yml                 # PR 门禁：typecheck / lint / test / 迁移 dry-run / build
│  │  └─ deploy.yml             # 手动触发 → 构建镜像 → 部署（production 需审批）
│  ├─ CODEOWNERS                # 自动指定 review 人
│  ├─ pull_request_template.md  # PR 自检清单
│  ├─ dependabot.yml            # 依赖每周检查
│  └─ ISSUE_TEMPLATE/
│     ├─ bug.yml
│     └─ feature.yml
├─ .gitignore
└─ .gitattributes
```

## 使用前要改的三处

1. **`CODEOWNERS`**：把 `@your-org/erp-core` 等换成你的真实组织/团队，否则 GitHub 会忽略这些规则。
2. **`ci.yml`**：`pnpm` 版本、Node 版本、脚本名（`typecheck` / `lint` / `test` / `db:migrate:check`）要和你 `package.json` 对齐；没有的脚本先删掉对应 step。
3. **`deploy.yml`**：Secrets 需要在仓库里配置：

| Secret | 用途 |
|---|---|
| `ACR_REGISTRY` | 阿里云容器镜像服务地址 |
| `ACR_USERNAME` / `ACR_PASSWORD` | 镜像仓库账号 |
| `DEPLOY_HOST` / `DEPLOY_USER` / `DEPLOY_SSH_KEY` | 目标服务器与部署密钥 |

## 仓库设置清单（建仓后 10 分钟内做完）

- [ ] 私有仓库 + 组织级强制 2FA
- [ ] `main` 分支保护：PR + 1 approval + status check `ci/verify` + linear history + 禁止 force push
- [ ] 合并方式只保留 **Squash merge**
- [ ] 新建 `staging` / `production` 两个 Environment，`production` 配审批人
- [ ] 开启 Secret scanning 与 push protection
- [ ] Actions 权限设为「只读默认 + 按需提升」

## 本地初始化

```bash
git init -b main
cp -r github-starter/.github .
cp github-starter/.gitignore github-starter/.gitattributes .
git add .
git commit -m "chore: 初始化仓库骨架"
git remote add origin git@github.com:<org>/erp.git
git push -u origin main
```

## 约定

- 分支：`feat/*`、`fix/*`、`chore/*`、`hotfix/*`，生命周期 ≤ 3 天
- 提交：Conventional Commits（`feat(scope): ...`）
- PR：≤ 400 行，关联 Issue，CI 绿才可合
- 发布：打 tag → GitHub Release → 镜像 tag 与 git tag 一致

详细规则见 `14-GitHub版本管理与协作规范.md`。
