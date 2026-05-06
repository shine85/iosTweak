# SHINE_MEMORY.md - 项目部署与环境管理记忆

## 1. 架构概览
- **前端框架**: React + Vite
- **基础设施**: Firebase (Auth, Firestore, Storage)
- **部署方案**: 
  - **CI/CD**: GitHub Actions (验证编译)
  - **生产环境**: 个人服务器 Docker Compose (使用 Node 镜像运行 Express 服务)
- **变动记录**:
  - 修正了 Dockerfile 仅部署静态资源导致 API 404 的问题。现在 Dockerfile 使用 Node 运行时同时托管前端和 API。
  - server.ts 端口改为支持环境变量 `PORT` (默认 3000)。
  - docker-compose.yml 更新了端口映射 (8080:3000) 并添加了 AI 密钥和 GITHUB_TOKEN 的环境透传。
  - GitHub 默认仓库设为 `shine85/iosTweak`。
  - **更新了 AI 生成 Tweak 的系统提示词 (Prompt)**，使其更符合顶尖 iOS 逆向安全专家的角色定位。
- **变量管理**: 采用 Vite 环境变量注入模式（构建时注入）以及服务端运行时环境变量。

## 2. 关键配置
### 环境变量 (Vite)
- 变量名前缀必须为 `VITE_` 才能在客户端访问。
- `import.meta.env.VITE_FIREBASE_*` 模式已在 `/src/lib/firebase.ts` 中实现。

### 部署链条
1. **GitHub Secrets**: 存储 Firebase 所有配置，用于 GitHub Actions 的 `npm run build` 测试。
2. **服务器 .env**: 在生产服务器上手动存放，`docker-compose.yml` 通过 `args` 注入 `Dockerfile`。
3. **Dockerfile**: 使用多阶段构建（Node.js 编译 -> Nginx 托管）。

## 3. 安全与合规
- `.gitignore` 已配置屏蔽所有 `.env*` 文件和 `firebase-applet-config.json`。
- 本地 `.env` 已删除，严防密钥泄露至公共仓库。

## 4. 遗留问题 / 待办
- [x] 全局 Node.js 版本已从 20 升级至 24 (Dockerfile & GitHub Actions)。
- [x] 彻底移除 GitHub Action 中的 `cctools-port` 依赖，改用 `ldid` 手动安装版本 (v1.1.3)。
- [x] 切换至 `theos/toolchain` v2.1 解决 sbingner 工具链下载 404 及文件格式不兼容问题 (v1.1.3)。
- [x] 统一使用 `docker-compose.yaml` 后缀，并注释掉 `environment` 配置由 Web 端管理。
- [x] 更新 GitHub Actions 插件 (checkout, setup-node) 版本以消除 Node 20 弃用警告 (v1.1.0)。
- [x] 移除 GitHub Action 中引起干扰的 Node 24 强制环境变量 (v1.1.3)。
- [ ] 验证服务器上的 Firebase Auth 域名授权 (Authorized Domains) 是否包含生产域名或公网 IP。
- [ ] 若使用 Firestore，需确保 `firestore.rules` 已部署。

-- *最后更新: 2026-05-06*
