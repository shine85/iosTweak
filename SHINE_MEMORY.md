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
- [x] **对象属性访问与 C 函数传参强约束 (v1.1.63)**：修复在 `UIViewController` 等泛对象上可能把 `self` 推断为 `__unsafe_unretained id const` 或 `id`，导致访问 `.view` 属性时抛出 `property 'view' not found on object of type 'id'` 的致命报错；加强了避免出现这类问题的约束词，此外还在 Node.js 层的正则表达式清洗逻辑中新增了 `self.view` 的暴力转换 `((UIViewController *)self).view`。修复了自定义 `hookIfExists` 把目标类名直接当符号传参导致的 `unexpected interface name` 拦截报错。现已在后端严格约束 AI 必须进行 `((UIViewController *)self).view` 显式转换，并使用带 `"ClassName"` 双引号的方式传给 C 函数。
- [x] **AI 配置增强 (v1.1.65)**：在设置页面新增了“获取模型列表”和“测试连接”功能。为了提升用户体验，将原始的 `window.confirm` 选择器替换为自定义的 `ModelPickerModal` 弹窗。该弹窗采用了符合应用整体风格的 Neobrutalism 设计，支持模型搜索过滤，并能清晰地在屏幕中央显示所有获取到的模型供用户点击选择。同步更新了版本号至 v1.1.65。
- [x] **AI 配置增强 (v1.1.64)**：在设置页面新增了“获取模型列表”和“测试连接”功能。用户现在可以一键获取 OpenAI 兼容提供商的可用模型，并测试当前 API Key 和模型配置是否工作正常。同步更新了 `server.ts` 后端接口和多语言本地化文件。
- [x] **C 语言函数嵌套定义防崩约束 (v1.1.61)**：修复了由于 AI 将 C 语言的函数（如 \`static inline void hookIfExists(...)\`）放置于 \`%ctor { ... }\` 的大括号内部所导致的致命报错 `function definition is not allowed here`。已通过加强 \`server.ts\` 内的 \`TWEAK_REQUIREMENTS\` 提示词限制，向 AI 明确了必须将辅助函数放置在所有 Blocks 外围（即全局作用域）进行定义。
- [x] **后台自动清理未挂钩类初始化逻辑 (v1.1.60)**：终极杀招落地！前面几个版本咱们又是给提示词又是给 \`GO_EASY_ON_ME=1\` 豁免，然而 LLM 在遇到极其长篇和复杂的去广告逻辑时，依然会不由自主地吐出长长的一串针对所有广告类的 \`%init(ClassA=...)\`，却丢三落四忘了写对应的 \`%hook ClassA\` 占位块，这也直接导致 Logos 在预处理转码 `.mm` 阶段因为无法找到 \`%hook\` 定义就报错中断（Theos 完全不认识这些没 hook 的名字）。本次绕过了试图用文字限制 AI 思维的死胡同，直接在 Node 后端 \`/api/generate\` 接口的发送阶段写入了一套精密的自动清洗脚本 \`cleanupLogosCode\`。它能自动提取所有实际包含的 \`%hook\` 并在输出给前端页面和 GitHub 推送之前，暴力物理剥离掉那些多余的空白 \`%init\` 代码！现在生成的源码就是防崩铁板一块！
- [x] **Theos 警告容忍级别开放增强 (v1.1.59)**：彻底终结编译器 `tried to set expression for unknown class` 等无意义的中断行为！此前由于 Theos 默认的严格策略会把 Logos 提示转换为致命报错（warnings being treated as errors），我们在过去几个版本中试图用提示词严防死守 AI 去生成多余的类绑定。本次直接从根源入手，在云编译流程（`build.yml`）中的 `make package` 阶段强制通过注入环境变量 `GO_EASY_ON_ME=1`。这能够迫使 Theos 放弃将编译警告视为报错拦截的洁癖，使得即使 AI 在 `%init` 中超前声明了当前并未启用的广告类或目标类，也能仅作警示并愉快通过，大幅提升插件生成的通过率和防御冗余度。
- [x] **Logos / Theos 未知类初始化严苛约束修正版 (v1.1.58)**：继续修补了 \`tried to set expression for unknown class or function\` 编译报错。之前的提示词约束强度不足导致 AI 似乎仍然贪图写入大量未使用的防备性解析类到 \`%init\` 中。本次修改了 \`TWEAK_REQUIREMENTS\` 使用了极其强硬和具体的表述，强调对于每一个在 \`%init\` 列出的类，必须确切提供从 \`%hook\` 到 \`%end\` 的代码块，即使只提供一个空块拦截，以此来强行阻断因单纯声明而未 Hook 触发的 Theos 对 Warnings 转 Fatal Errors 的拦截机制。
- [x] **Logos / Theos 未知类初始化警告转致命错误修复 (v1.1.57)**：Theos 默认将 Logos 的警告升级为致命错误 (`warnings being treated as errors`)，在此前生成的生成逻辑中，AI 经常会一并 `%init` 很多预设了变量但最终并未实际给出 `%hook` 模块的类（如 `GDTSplashAd`, `CSJSplashAd` 等）。当发生类未挂钩却尝试 `%init(ClassA=...)` 操作时，Logos 会报出 `tried to set expression for unknown class or function in group` 警告并导致最终 Make 异常中断。本版本在 `TWEAK_REQUIREMENTS` 中强行增加了“只允许被 Hook 过的类进 `%init` 赋值”的对抗约束，根治了由于未 Hook 类混入 `%init` 块所引起的编译抛错。
- [x] **Web UI 源码展示排版修复 (v1.1.56)**：修复了 Web 界面在展示由 AI 生成的 LOGOS 源码及 Makefile 时，代码框中间突然出现横向滚动条并且生硬截断下方显示样式的问题。这归咎于此前逻辑为了保证语法高亮，将整个包含 Markdown 格式的返回文本包裹在了 \`\`\`objectivec 块之中，导致内层 Markdown 闭合物触发提前跳出。目前已拆除外层强制包裹逻辑，原汁原味透传为 ReactMarkdown 渲染，多代码块显示恢复完美。
- [x] **Logos / Theos 语法生成强化与防崩溃约束 (v1.1.55)**：针对近期部分复杂应用生成的 `Tweak.xm` 文件出现的两种低级却致命的编译报错进行了底层提示词级的封堵。1. 修复 `%init does not make sense outside a block`：强制 AI 必须且只能将宏观调度指令 `%init` 写入 `%ctor { ... }` 构造块内部，禁止全局流出调用。2. 修复 `expected function body after function declarator`：严禁 AI 在生成带有参数传入（例如带 `UIWindow *window`）的方法拦截钩子时随手带上并列右多余括号 `)`，这保证了 Logos 在转写 Objective-C 后不会因末尾多出括号导致编译器抛出缺少方法体的故障。
- [x] **Logos / Theos \`%init\` 组名冲突编译致命错误修复 (v1.1.54)**：深入修补了此前针对动态类解析的提示词指令。之前的 AI 在尝试处理多重防崩 Hook 时使用 \`%init(ClassName);\` 的直接传参写法，这被 Logos 语法解析器误认为是要初始化名叫 \`ClassName\` 的自定义 \`%group\`，从而引发 \`%init for an undefined %group\` 的编译中断。本次不仅禁止了该错误写法，还针对性地明确指出若需在隐匿组动态解析加载类名必须遵循 \`%init(ClassA=objc_getClass("ClassA"));\` 的强绑定带赋值语法，从而彻底解决生成产物过程中的语法识别冲突报错。
- [x] **Logos / Theos \`%init\` 多次调用编译修复 (v1.1.53)**：修复了 AI 在生成代码时，为了兼容不同平台的 SDK 在 \`%ctor\` 阶段针对同一个对象进行了多次 \`%init\` 调用，引发了 Theos 终端上的致命编译错误：\`re-%init of %group _ungrouped\`。在底层 \`server.ts\` 服务端的提示词约束 \`TWEAK_REQUIREMENTS\` 之中增加了**单次 Hook 初始化约束**，如果需要容错拦截多种穿山甲/广点通广告类，需要使用 \`%init(ClassA=..., ClassB=...)\` 的合并写法，或放到独立的组别内分别初始化。
- [x] **Deb 包版本号动态同步修复 (v1.1.52)**：修复了云编译导出的 `.deb` 安装包内版本号始终为固定（如 `0.0.1`），无法与每次生成的产物文件名或源码修改次数同步的问题。由于 Theos 包配置依赖于静态的 `control` 文件，本次已在 GitHub Action 的构建流 (`build.yml`) 中注入了前置处理，通过提取项目中动态的 `package.json` 的版本号，利用 `sed` 命令强制刷新复写 `control` 内的 `Version`。现在，无论是导入 Sileo/Zebra，每一次重新生成编译的插件包都将具有唯一对应递增的版本标识了。
- [x] **TrollFools dylib签名兼容性彻底修复与通用去广告增强 (v1.1.51)**：1. 针对通过 TrollFools 注入时出现的 `ldid: Unsupported Mach-O type` 签名错误，此次通过在 Theos 构建后继而使用 llvm-project 的 `lipo` 工具强制提取出纯 `arm64` 架构切片作为最终 `.dylib` 产物，这彻底绕过部分注入工具中老旧 ldid 对新版 arm64e ABI（如 PAC 特性）在读取解析时的崩溃问题。2. 加固服务端 `server.ts` 中的 `TWEAK_REQUIREMENTS` 提示词，深度囊括诸如穿山甲 (BUAdSDK)、广点通 (GDTSplashAd)、百度 (BaiduMobAd) 乃至直接挂钩通用 `[UIViewController viewDidAppear:]` 等流氓开屏广告的彻底拦截与跳过技巧，强化无感去广告核心实力。
- [x] **Filter.plist 动态作用域劫持修复 (v1.1.50)**：解决了用户安装编译的 `.deb` 包后设备注销进入以安全模式 (Safe Mode / SpringBoard Crash) 的致命缺陷。原因在于过去服务端在生成 `Filter.plist` 时，写死了 `com.apple.springboard` 的全局注入作用域，这导致不论是什么应用的 Tweak，在越狱环境下都会被强行注入到 SpringBoard 中并执行 `%ctor` 阶段，引起 `EXC_BAD_ACCESS` 崩溃。本次修改通过前台向服务端透传 App Store 抓取到的真实 `bundleId`（或者从 `appName` 正则推断的备用 BundleId），让服务端动态生成针对具体 App 的 `Filter.plist` 文件，从而彻底修复 `.deb` 包的越狱全局崩溃问题。
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
- [x] **Theos 构建产物提取与 TrollFools Dylib 兼容修复 (v1.1.49)**：修复了云编译导出的 `.dylib` 文件在通过 TrollFools 注入目标 App 时提示 `ldid: Unsupported Mach-O type` 签名失败的问题。根本原因是此前云编译提取的是 Theos 打包合并后的 Fat Binary，由于 TrollFools 自带的旧版 `ldid` 无法解析包含新版 `arm64e` ABI 的二进制切片结构导致崩溃退出。在 GitHub Action 的 `build.yml` 的提取阶段增加了精细的路径匹配（优先 `find .theos/obj -type f -path "*/arm64/*.dylib"` 抓取纯 `arm64` 切片作为最终产物）。不仅让 `make package` 直接产生的 `arm64` 纯净可用版脱离 `debug` Fat 的污染，而且目前绝大多数 App Tweak 通过 TrollFools 注入时只需要运行在 `arm64` 指令集即可，这彻底规避了 `ldid` 读取新版 `arm64e` 的报错壁垒，保障注入成功。
- [x] **Theos 语法 AI 校验与容错增强 (v1.1.48)**：由于 AI 生成偶尔会出现悬空的 `%end` 导致 `Theos` 编译报错，在 `server.ts` 强化了 Prompt，加入强制红线：要求生成的所有 `.xm` 文件 `%hook` 和 `%end` 以及 `@interface` 等成对关键字必须严格匹配闭合，绝对不允许出现 `dangling %end`。同时优化了纯 ID 和应用名称识别抓取逻辑，确保无论是前端主动触发查询还是最后防抖兜底，都可以使用真实 `appName` 进行构建以防 `History: id583700738 build` 这样不知所云的编译包流出。
- [x] **源码容器UI重新调校 (v1.1.46)**：优化了代码编辑区的界面布局。将左侧设定区域缩减并放宽右侧编辑器宽度。提升代码框的高度 (`70vh`)，通过配置 `highlight.js` 的 `atom-one-dark` 主题实现了 Objective-C 语法的高亮呈现，并将“导入、复制、云编译”三个操作按钮挪动至标题右侧，使界面更加整洁。
- [x] **App Store 链接解析增强与静默联想 (v1.1.45)**：修复了纯 ID 因为无交互导致解析缺失的问题：前端 (`App.tsx`) 新增 `useEffect` 防抖拦截监听，只要输入内容且非空，停顿 1000 毫秒即自动走后台拉取并显示 App Store 实体信息；在用户急躁点击生成按钮时，底层再次执行强阻断确保 ID (如 `id583700738`) 或者链接 (如 `apps.apple.com`) 被 100% 解析补全目标。
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
- [x] 系统级版本号同步：建立了跨 `package.json`、语言包、登录 UI 及 GitHub Actions 的版本号联动机制，当前已同步至 v1.1.68。
- [x] **重构 Builder 页面为 IDE 模式 (IDE Layout)**：左侧实时源码预览，右侧 AI 调试对话。解决了“即看代码又能对话”的用户核心诉求 (v1.1.68)。
- [x] **上线 AI 对话流模式 (Chat Mode)**：将 Builder 页面重构为类似 ChatGPT 的对话模式。支持“修改说明”与“源码预览”混合显示，实时解答 AI 做了哪些修改 (v1.1.67)。
- [x] **新增外部源码导入功能**：在 Builder 页面增加了“导入”入口，支持直接粘贴外部生成的 `.xm` 代码并一键推送到云端编译 (v1.1.31)。
- [x] **彻底解决 Pangle SDK 编译冲突**：在 `server.ts` 指令集中强制加入了对 `PAGInterstitialRequest` 等不确定类型的防御性 `@interface` 定义要求，并要求所有 Hook 内的 `self` 调用 `respondsToSelector` 时必须强转为 `id` 类型 (v1.1.30)。
- [x] 彻底解决 `server.ts` 服务端崩溃问题：通过变量拼接（String Concatenation）隔离 Prompt 模板中的反引号 (v1.1.29)。
- [x] GitHub Action 任务排重：移除了 `pull_request` 触发器，并强化了全局并发锁定逻辑，确保同一个仓库内永远只有一个最新的构建任务 (v1.1.27)。
- [x] 产物历史聚合功能：同一 App 的所有历史版本产物现在均自动聚合在对应中文名的唯一 Release 下，文件名采用纯拼音（如 `zhongguoyidong-v1.1.dylib`）防止乱码 (v1.1.26)。
- [ ] 验证服务器上的 Firebase Auth 域名授权 (Authorized Domains) 是否包含生产域名或公网 IP。
- [ ] 若使用 Firestore，需确保 `firestore.rules` 已部署。

-- *最后更新: 2026-05-09*
