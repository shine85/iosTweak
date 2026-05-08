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
- [x] 彻底移除 GitHub Action 中的 `cctools-port` 依赖，改用 `ldid` 手动安装版本并修正下载路径为 `ProcursusTeam` (v1.1.5)。
- [x] 切换至 `theos/toolchain` 下载失败，现改用官方安装脚本使用的 `L1ghtmann/llvm-project` 预编译工具链 (v1.1.4)。
- [x] 统一使用 `docker-compose.yaml` 后缀，并注释掉 `environment` 配置由 Web 端管理。
- [x] 更新 GitHub Actions 插件 (checkout, setup-node) 版本以消除 Node 20 弃用警告 (v1.1.0)。
- [x] 移除 GitHub Action 中引起干扰的 Node 24 强制环境变量 (v1.1.3)。
- [x] 在 Web UI 设置页面添加配置备份导出及恢复功能。
- [x] 修复 `/api/github-push` 直接将带有 Markdown 和 Makefile 的完整对话推送进 `Tweak.xm`，导致 Theos 出现 `dangling %end` 甚至严重编译失败的问题 (v1.1.6)。
- [x] 修复 GitHub Actions 编译时因应用中文名被安全名过滤剥离（导致仅剩默认空包名）引起的名称冲刷和覆盖问题。优化 `server.ts` 强行保留后缀以解决包名一致的Bug (v1.1.7)。
- [x] 优化 Action Workflow 步骤，实现多 Scheme 执行，产物分离并且严格按照 `ios-{appName}-v1.1.X.dylib`，`{appName}-arm64_arm64e-rootless(无根).deb`， 以及 `{appName}-arm64_arm64e-roothide(隐根).deb` 输出，明确标识出在 Dopamine 中兼容跨平台的 arm64 及 arm64e 双向架构特性 (v1.1.9)。
- [x] 修复并严格规范打包产物的输出名称格式为：`ios-{APP英文拼音名}-v1.1.9.dylib`、`{APP英文拼音名}-arm64-rootless(无根).deb` 及 `{APP英文拼音名}-arm64e-roothide(隐根).deb`，其中 `{APP英文拼音名}` 取自转化后的安全包名标识，以符合多环境及文件标准需求 (v1.1.10)。
- [x] 采用 `roothide/theos` 特供分支替换原主线 Theos 源，一次性原生解决 `roothide package scheme does not exist` 的错误，恢复对 Dopamine RootHide (隐根) 跨平台直接打包的支持及 `arm64_arm64e` 双架构构建能力 (v1.1.11)。
- [x] 引入 `pinyin-pro` 处理由中文转换拼音包名标识问题，保证以全英文拼音及特定命名格式呈现内部包名避免 iOS 在注入或Theos打包时不支持中文字符而导致的验证错误 (v1.1.8)。
- [x] 新增自动化 Release 发布环节，并将各种架构的打包产物作为标签上传至 Releases（包含 dylib、rootless、roothide），且能够保持只存储最新的 3 个标签以节约存储并维持整洁 (v1.1.12)。
- [x] 修复 `server.ts` 在处理 AI 生成的 Makefile 变量时（如 `${TWEAK_NAME}_FILES` 等），由于过度依赖硬编码正则引发在后续编译阶段出现“No files to link”或“找不到文件”的问题。现已采用读取动态现有变量名前缀并全局替换新工程变量名的修复方案，彻底保障 Theos 包体编译及链接阶段读取不到源文件的问题 (v1.1.13)。
- [x] 在 DYLIB源码生成器页面 下方增加上下文对话框和 `/api/modify` 接口，以便用户通过 AI 修改或追加现有由 AI 生成的 Dylib LOGOS 代码的更多需求。
- [x] 修复 `Tweak.xm:2:1: error: unknown type name` 等在 Github Action 构建时的编译错误，通过增加对底层 AI Prompt 生成指令强制要求中文解说内容一定要被注释包裹，防止裸露中文对 Theos 的 Makefile 链接机制造成致命破坏 (v1.1.14)。
- [x] 添加并详细编写了 `README.md`，并在其中增加了针对**符号研究员**使用方法的说明。
- [x] 每次修改代码后都需要对应更新 `package.json` 中的版本号。
- [x] 修复 GitHub Action 打包时 `Release.tag_name already exists` 的报错，给 TAG_NAME 追加了 `$RANDOM` 随机数以确保不同并发执行产生的 Tag 绝对唯一 (v1.1.15)。
- [x] 优化 Release 逻辑：根据 APP_NAME 归类 Tag (latest-AppName)，确保同一个 App 的多次编译产物覆盖更新在同一个 Release 中，并实现全局只保留最近活跃的 3 个 Release 的自动清理策略 (v1.1.16)。
- [x] 修复 `Tweak.xm` 编译时因 AI 输出 Markdown 标题（##）导致的语法错误：加固了 AI Prompt 的禁令，并在后端增加了自动剔除源码中无效 Markdown 标题行的清洗逻辑 (v1.1.17)。
- [x] 解决推送后 GitHub 任务堆积问题：引入 `concurrency` 控制，自动取消旧的任务，只保留最后一次推送生成的构建任务 (v1.1.18)。
- [x] 彻底解决 `Tweak.xm` 编译报错：加固后端清洗中心，不仅剔除 Markdown 标题，还增加了对 `---` 等分割线的拦截，并自动将全角括号纠偏为半角括号 (v1.1.19)。
- [x] **App Store 链接解析增强 (v1.1.44)**：修复了 `/api/search-appstore` 接口在解析国区包含具体 ID 链接时的 fallback 逻辑。新增对 `apps.apple.com/[country]/app/...` URL 格式的正则匹配，并强制默认使用 `country=cn` 作为 ID 纯检索时的缺省抓取区域，提高中国区应用识别准确率。
- [x] **App Store 信息逆向增强部署 (v1.1.43)**：
  - 新增 `/api/search-appstore` 接口，支持通过应用名称、App Store ID (id...) 和 Bundle ID 主动爬取获取真实 iOS 市场应用元数据。
  - 前端 (`App.tsx`) 结合后端能力新增“解析 App Store 链接”入口，获取真实 Bundle ID 和链接地址，并在向 AI 提交生成任务时，自动附带解析出的 Bundle ID 与链接详情。
  - Prompt 体系强化，加入 Instagram、X(Twitter)、Snapchat 等国外应用的专属拦截生成逻辑要求及 `<#AppSpecificClassName#>` 类的占位符。
- [x] **同源实体自动归一化 (v1.1.42)**：针对用户输入中“中国移动”、“中国移动(手机营业厅)”、“id583700738”被识别为不同应用并导致生成产物不一致的问题，在 `server.ts` 后端 Prompt 中引入了“目标实体规范”硬约束，强制 AI在内部抽象时将多称呼进行统一的 Bundle ID 与特征映射，确保相同应用的不同别名输出的 Hook 源码、策略和架构 100% 相同。
- [x] **目标对象识别能力升级 (v1.1.41)**：增强了 `server.ts` 后端 Prompt 对于参数的智能推断能力，及前端 `App.tsx` 中的占位符提示，现已全面支持在“目标对象”中直接输入应用名称、Bundle ID (如 com.tencent.xin) 或 AppStore ID (如 id414478124)，进一步提升跨区应用的分析精准度。
- [x] **架构硬化与监控升级 (v1.1.40)**：重构了后端日志审计中间件，统一了 Tweak 生成的安全性指令集，并确保 `arm64e` 架构及基石依赖在所有生成模式下强制生效。
- [x] **上线 App Store 快捷搜索功能**：在 Builder 页面目标对象输入框下方新增了“App Store 搜索”入口，支持一键跳转并定位目标应用的商店页面，辅助开发者快速确认版本及 Bundle 信息 (v1.1.39)。
- [x] **全方位系统监测与架构扩展**：在 `server.ts` 中引入了耗时监测中间件及精准错误捕获逻辑，并在 Prompts 指令集中强制加入了 `arm64e` 架构支持及全球热门应用（TikTok, X, WeChat 等）的预设模板 (v1.1.38)。
- [x] **彻底修复 `MSHookMessageEx` 与修改模式冲突**：重构了 `server.ts` 源码，将基石依赖（substrate.h）及方法签名（Interface）要求提取为共享指令集，确保在“修改/对话”模式下 AI 依然遵循编译安全准则 (v1.1.37)。
- [x] **修复 `MSHookMessageEx` 未定义报错**：在后端指令中强制要求使用 Substrate 函数时必须声明或引用 `substrate.h`，解决了防止检测模式下的编译中断 (v1.1.36)。
- [x] **修复服务端 `server.ts` 崩溃**：转义了 Prompt 模板内嵌套的反引号（Backticks），根治了导致 Node.js v24 及 esbuild 解析失败的语法冲突 (v1.1.35)。
- [x] **上线去广告专项强化模块**：针对开屏广告和主流广告 SDK（穿山甲、优量汇等）建立了“爆头式”拦截指令集，强制 Hook 早期加载方法及代理回调 (v1.1.34)。
- [x] **解决 `no known instance method` 编译崩溃**：升级后端 Prompt 指令，强制 AI 必须为所有 Hook 或调用的 Class 提供 `@interface` 补全方法签名 (Signature) (v1.1.33)。
- [x] **根治 NSClassFromString 重定义冲突**：在 `server.ts` 后端增加了正则表达式强制过滤逻辑，自动剔除代码中错误的前向声明 (v1.1.32)。
- [x] 系统级版本号同步：建立了跨 `package.json`、语言包、登录 UI 及 GitHub Actions 的版本号联动机制，当前已同步至 v1.1.40。
- [x] **新增外部源码导入功能**：在 Builder 页面增加了“导入”入口，支持直接粘贴外部生成的 `.xm` 代码并一键推送到云端编译 (v1.1.31)。
- [x] **彻底解决 Pangle SDK 编译冲突**：在 `server.ts` 指令集中强制加入了对 `PAGInterstitialRequest` 等不确定类型的防御性 `@interface` 定义要求，并要求所有 Hook 内的 `self` 调用 `respondsToSelector` 时必须强转为 `id` 类型 (v1.1.30)。
- [x] 彻底解决 `server.ts` 服务端崩溃问题：通过变量拼接（String Concatenation）隔离 Prompt 模板中的反引号 (v1.1.29)。
- [x] GitHub Action 任务排重：移除了 `pull_request` 触发器，并强化了全局并发锁定逻辑，确保同一个仓库内永远只有一个最新的构建任务 (v1.1.27)。
- [x] 产物历史聚合功能：同一 App 的所有历史版本产物现在均自动聚合在对应中文名的唯一 Release 下，文件名采用纯拼音（如 `zhongguoyidong-v1.1.dylib`）防止乱码 (v1.1.26)。
- [ ] 验证服务器上的 Firebase Auth 域名授权 (Authorized Domains) 是否包含生产域名或公网 IP。
- [ ] 若使用 Firestore，需确保 `firestore.rules` 已部署。

-- *最后更新: 2026-05-08*
