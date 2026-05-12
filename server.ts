import express from "express";
import path from "path";
import fs from "fs/promises";
import { fileURLToPath } from "url";
import { GoogleGenAI } from "@google/genai";
import dotenv from "dotenv";
import { createServer as createViteServer } from "vite";
import { pinyin } from "pinyin-pro";

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function startServer() {
  const app = express();
  const PORT = process.env.PORT ? parseInt(process.env.PORT, 10) : 3000;

  app.use(express.json());

  // 请求耗时监测与详细日志中间件
  app.use((req, res, next) => {
    const start = Date.now();
    const { method, url } = req;
    
    res.on('finish', () => {
      const duration = Date.now() - start;
      const status = res.statusCode;
      const logMsg = `[${new Date().toISOString()}] ${method} ${url} - Status: ${status} - Time: ${duration}ms`;
      
      if (status >= 400) {
        console.error(`\x1b[31m${logMsg}\x1b[0m`);
      } else {
        console.log(`\x1b[32m${logMsg}\x1b[0m`);
      }
    });
    next();
  });

  // 共享的 Tweak 生成需求指令集 (v1.1.53 强化版)
  const TWEAK_REQUIREMENTS = `
目标实体规范（极度重要）：
- 逻辑归一化：不论用户提供的目标是官方应用名（如“中国移动”）、AppStore副标题名称（如“中国移动(手机营业厅)”）、Bundle ID 还是 App Store ID，你必须首先在内部推理阶段将其归一化解析为同一对象的标准包体特征，并生成对应的、准确度高的去除广告逻辑。
- 产物一致性：最终的注入策略与生成产物必须 100% 完全一致。

深度去广告与开屏拦截策略（极其关键）：
- **一键全包裹绝杀（零容忍用户反复调试） (CRITICAL)**：当用户请求去除某 App 的广告时，你**绝对不能只给出一段简单的提示或残缺代码要求用户去验证和抓包**。你必须在首次回答时直接提供“无死角终极全家桶”：包含中国区与海外所有主流广告 SDK (CSJ, GDT, BU, KSAd, BaiduMobAd, AdMob, PAG 等)的开屏满屏与插屏拦截宏、特定 App 及相关变种的猜测式全覆盖、外加基于生命周期 (UIWindow/UIViewController) 的全局双重兜底杀软，以及必须配套完善的 `delegate` 伪造回调来解决极大概率导致的卡白屏问题。你的目标是保证用户编译一次即可 100% 根除所有开屏及应用内扰人广告。
- **防止白屏、黑屏零容忍 (CRITICAL 规则)**：在满足“一键绝杀”的同时，**任何拦截行为都绝不能导致业务界面出现白屏、黑屏、卡死或编译出错！** 这意味着：1. 强杀开屏 UIWindow 时，务必确保底层主业务 Window 不被牵连，并且能正常获得焦点（如有必要使其 makeKeyAndVisible）。2. 如果拦截的是带有 `delegate` 的控制器，极其可能导致主路径被卡住，必须伪造如 `splashAdClosed:`, `splashAdDidDismiss:` 等回调通知委托方继续进入主页。3. 拦截 UIViewController 展示时不能只是简单把 `view.hidden=YES`，对模态视图必须还要执行 `dismiss`（同样要注意前置强转防编译错）。4. **编译红线**：严禁在推断未知的 id 类型作用域内使用点语法（如 `self.view`, `self.delegate`），这是大量编译崩溃的根源，必须强制用 `((UIViewController *)self).view` 或者 `performSelector:`。
- 开屏广告 (Splash Ads) 必须根除：中国区应用广泛使用穿山甲 (CSJ / BUAdSDK)、广点通 (GDT)、百度 (BaiduMobAd) 及快手 (KSAd) SDK。你必须强制生成通用的 Hook 逻辑，拦截这些基类的初始化和展示方法。
  - 例如 Hook \`GDTSplashAd\`, \`CSJSplashAd\`, \`BUSplashAdView\`, \`BaiduMobAdSplash\`, \`KSAdSplashViewController\` 等类的 \`loadAdAndShowInWindow:\`, \`showAdInWindow:\`, \`loadAd\` 等方法，并直接阻断（无需调用 %orig）。
- **视图层强杀与防白屏**：当拦截 \`UIViewController\` 展示广告的方法时，**必须显式强转** \`((UIViewController *)self)\`。例如 \`if (((UIViewController *)self).presentingViewController) { [((UIViewController *)self) dismissViewControllerAnimated:NO completion:nil]; }\`。或者尝试将其从 \`((UIViewController *)self).view.superview\` 移除。严禁未强转直接调用 \`self.presentingViewController\`。
- **自动化跳过与防白屏 (CRITICAL)**：若拦截了开屏广告展示且未调用 \`%orig\`，应用极大概率卡白屏！你**必须**向其 \`delegate\` 发送广告已关闭的回调消息。另外对于 \`%ctor\`，你应该尽早触发拦截，例如在 \`%ctor\` 中立即准备并调用类似 \`killSplashWindow()\` 的函数清理残余，强制触发 \`splashAdClosed:\` 回调等。
- 针对特有应用（例如“中国移动”）：强烈关注内部专用广告类（如 \`CMSplashManager\`, \`CMSplashViewController\`, \`CMSplashAd\`, \`BiddingSplashAd\`, \`CMAdSplashView\`）。**强制拦截这些类的 \`init\`, \`initWithFrame:\`, \`loadAd\` 并直接返回 nil 或阻断**。这比稍后移除视图更有效。
- **终极大杀器（通用开屏防白屏兜底）**：双重保险拦截：第一重兜底：直接全局 Hook \`UIWindow\` 的 \`makeKeyAndVisible\`、\`becomeKeyWindow\` 和 \`setHidden:\`，如果 \`NSStringFromClass([self class])\` 包含 \`SplashWindow\`, \`AdWindow\`, \`PAGWindow\`, \`CSJWindow\` 等广告 SDK 私有 Window，直接调用 \`%orig(YES)\` 隐藏并阻断。第二重兜底：全局 Hook \`UIViewController\` 的 \`viewWillAppear:\` 和 \`viewDidAppear:\`，判断 \`NSStringFromClass([self class])\` 包含 \`Splash\`, \`Bidding\`, \`SplashAd\`, \`AdViewController\`, \`CMAd\` 等字眼，直接 \`((UIViewController *)self).view.hidden = YES;\`并处理 dismiss。
- **视图查杀绝对防误伤约束 (CRITICAL)**：**绝对禁止**拦截或遍历带 \`CM\`、\`ChinaMobile\` 或 \`Home\` 等中立/短前缀的普通视图，如果这么做你会引发应用页面级白屏误杀异常。只精确匹配完整的 SDK 类或带有 \`Splash\`, \`AdView\` 的明确类！

应用特定逻辑参考：
- **TikTok/抖音**：Hook \`AWEFeedAdModel\`, \`BDASplashManager\`。
- **WeChat/微信**：Hook \`WCBizMainViewController\`, \`MMUIViewController\` 的相关显示逻辑。
- **Instagram/X (Twitter)/Snapchat 等国外热门应用**：生成明确的代码去除信息流及视频中插广告。
- **通用防护**：识别 \`PAGSplashRequest\`。

代码实现 (Logos)：
- **单次 Hook 初始化约束**：在同一个 %group (或未命名默认组) 中，绝对不允许出现超过一次的 \`%init\` 操作。若需动态解析尚未加载的类，必须使用带赋值的语法，例如 \`%init(ClassA=objc_getClass("ClassA"), ClassB=objc_getClass("ClassB"));\`。**绝对严禁**使用 \`%init(ClassName);\` 这种只传名字不赋值的写法，因为这会被 Logos 误解析为初始化一个名叫 ClassName 的 \`%group\`，从而引发 \`%init for an undefined %group\` 致命错误！
- **未知类初始化防崩约束**：对于每一个你在 \`%init\` 中初始化的未知类，必须提供对应的 \`%hook\` 并在文件上方硬性声明其 \`@interface ClassName : UIViewController @end\` 或 \`UIView\`，这是防止 \`forward declaration\` 编译失败的关键！
- **成员属性与 @interface 编译约束 (CRITICAL)**：即使是已知框架未被直接包含头文件，或者任何动态 hook 类对象，如果你用了 \`self.presentingViewController\` 或 \`self.view\`，必须将其强转：\`((UIViewController *)self)\` 或者用 \`[self performSelector:]\`，并在顶部为每一个可能用到的类编写 \`@interface\` 且必须指定父类如 \`UIView\`/\`UIViewController\`。绝对不要只写一个 \`@class\`！
- **%init 位置约束**：所有的 \`%init\` 宏指令必须且只能放置在 \`%ctor { ... }\` 构造块内部！绝对不要在外部全局直接调用 \`%init;\`，否则会引发 \`%init does not make sense outside a block\` 致命编译错误。
- **Hook 语法约束**：在 Hook 带有参数的 Objective-C 方法时，**绝对禁止**在参数名称后面添加多余的右括号 \`)\`。例如正确写法是 \`-(void)loadAdAndShowInWindow:(UIWindow *)window { ... }\`，错误写法是 \`-(void)loadAdAndShowInWindow:(UIWindow *)window) { ... }\`（这会引发 \`expected function body after function declarator\` 编译错误）。
- **C 函数规范约束**：严禁在 \`%ctor { ... }\` 块内部、或者其他任何函数体/Block 内部直接定义 C/C++ 辅助函数（例如 \`static inline void hookIfExists(...)\`）。局部嵌套定义函数会引发 \`function definition is not allowed here\` 致命错误！任何辅助函数的定义必须放置在文件顶层全局作用域（所有 \`%hook\` 或 \`%ctor\` 的外围）。
- **常用辅助函数库 (Common Helpers)**：
  - 如果你需要遍历恢复视图，**必须且只能**使用以下标准实现（放在文件顶部）：
    \`static void forceRestoreSubViews(UIView *view) { if(!view) return; for(UIView *sub in view.subviews) { sub.hidden = NO; sub.alpha = 1.0; if(sub.subviews.count > 0) forceRestoreSubViews(sub); } }\`
  - 获取 KeyWindow 的现代适配方法：
    \`static UIWindow* get_keyWindow() { UIWindow *foundWindow = nil; if (@available(iOS 13.0, *)) { for (UIWindowScene* windowScene in [UIApplication sharedApplication].connectedScenes) { if (windowScene.activationState == UISceneActivationStateForegroundActive) { for (UIWindow *window in windowScene.windows) { if (window.isKeyWindow) { foundWindow = window; break; } } } if (foundWindow) break; } } if (!foundWindow) { foundWindow = [[UIApplication sharedApplication] valueForKey:@"keyWindow"]; } return foundWindow; }\`
- **对象属性点语法崩溃约束**：在被推断为 \`id const\` 的作用域内，**绝对禁止使用点语法**读取属性（如 \`self.presentingViewController\` 会导致各种找不到的问题）。你**必须强制进行显式前置接口转换**，例如写为 \`((UIViewController *)self).presentingViewController\` 或是 \`((UIViewController *)self).view.hidden = YES;\`。
- **类名传参安全防范**：在往自定义 C/C++ 辅助函数（如 \`hookIfExists(...)\`）传递目标类名时，如果参数是字符串，**必须带上双引号**写成 \`"ClassName"\`；如果参数是 Class，必须写成 \`objc_getClass("ClassName")\`。绝对禁止把裸的类名（如 \`GDTSplashAd\`）当作变量直接传参，这会导致 \`unexpected interface name: expected expression\` 报错阻断编译！
- **强制早期执行**：必须在 \`%ctor\` 中尽早执行动态初始化以确保拦截生效。
- **安全拦截与防白屏 (CRITICAL)**：严禁直接调用可能不存在的方法引发崩溃。如果阻断了广告的展示逻辑 \`%orig\`，必须处理 \`delegate\`。如果有 \`delegate\`，**绝对禁止直接写 \`self.delegate\` 或 \`self.hidden\`**（会引发 \`property not found on object of type '__unsafe_unretained id const'\` 致命编译错误！）对于 \`delegate\` 你**必须**使用 \`[self performSelector:@selector(delegate)]\` 提取。对于 \`hidden\`，必须强转：\`[(UIView*)self setHidden:YES];\`。最安全的做法是：
    \`#pragma clang diagnostic push\`
    \`#pragma clang diagnostic ignored "-Warc-performSelector-leaks"\`
    \`if ([self respondsToSelector:@selector(delegate)]) { id delegate = [self performSelector:@selector(delegate)]; if ([delegate respondsToSelector:@selector(splashAdClosed:)]) { [delegate performSelector:@selector(splashAdClosed:) withObject:self]; } else if ([delegate respondsToSelector:@selector(splashAdDidDismissFullScreenContent:)]) { [delegate performSelector:@selector(splashAdDidDismissFullScreenContent:) withObject:self]; } else if ([delegate respondsToSelector:@selector(splashAdDidClose:)]) { [delegate performSelector:@selector(splashAdDidClose:) withObject:self]; } else if ([delegate respondsToSelector:@selector(splashDidDismissScreen:)]) { [delegate performSelector:@selector(splashDidDismissScreen:) withObject:self]; } }\`
    \`#pragma clang diagnostic pop\`
    \`if ([self isKindOfClass:[UIView class]]) { [(UIView *)self setHidden:YES]; }\`
    \`else if ([self isKindOfClass:[UIViewController class]]) { [((UIViewController *)self).view setHidden:YES]; }\`
    如果没有 \`delegate\` 或无效，将其所在的整个界面大 Window 强杀（提取 \`self.window\` 或遍历），将根视图设为空并注销，强制底层大窗体获取焦点。
- **架构与版本注入支持**：生成的 Makefile 必须包含 \`ARCHS = arm64 arm64e\`。同时**必须配置版本号注入**，即在 Makefile 中加入 \`$(TWEAK_NAME)_LDFLAGS += -Wl,-current_version,1.0.0\`（1.0.0 可以替换为你设定的版本或宏）。这非常重要，否则 TrollFools 无法识别注入版本！
- **基石依赖**：所有 Hook 必须确保引入相应的 Foundation 框架类型定义，使用 \`MSHookMessageEx\` 必须 \`#import <substrate.h>\`。

防御对抗：
- 必须为所有可能用到的类提供声明 \`@interface\` 或 \`@class\`，防止编译器报 \`no known instance method\`。
- 严禁在 @class 列表中包含系统内置类型（如 NSString）。
`;

  // API 路由：搜索 App Store 信息
  app.get("/api/search-appstore", async (req, res) => {
    try {
      let { query } = req.query;
      if (!query || typeof query !== 'string') {
        return res.status(400).json({ error: "Missing query parameter" });
      }

      query = query.trim();
      let url = '';
      
      // 解析可能包含的 App Store 链接
      const urlMatch = query.match(/apps\.apple\.com\/([a-z]{2})\/app\/.*?id(\d+)/i);
      const idMatch = query.match(/^id(\d+)$/i);
      const bundleIdMatch = query.match(/^[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+$/i) || query.match(/^[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+$/i);

      if (urlMatch) {
        const country = urlMatch[1];
        const id = urlMatch[2];
        url = `https://itunes.apple.com/lookup?id=${id}&country=${country}`;
      } else if (idMatch) {
        const id = idMatch[1];
        // 默认加上 country=cn，否则中国区特有应用会查不到或者查到错误的外区应用
        url = `https://itunes.apple.com/lookup?id=${id}&country=cn`;
      } else if (bundleIdMatch && !query.includes(' ')) {
        url = `https://itunes.apple.com/lookup?bundleId=${encodeURIComponent(query)}&country=cn`;
      } else {
        url = `https://itunes.apple.com/search?term=${encodeURIComponent(query)}&entity=software&limit=1&country=cn`;
      }

      let response = await fetch(url);
      let data = await response.json();

      // 如果国内没查到，并且是纯 ID 或 bundleId 搜索，尝试一下美国区作为 fallback
      if ((idMatch || bundleIdMatch) && (!data.results || data.results.length === 0)) {
        const fallbackUrl = idMatch 
          ? `https://itunes.apple.com/lookup?id=${idMatch[1]}&country=us`
          : `https://itunes.apple.com/lookup?bundleId=${encodeURIComponent(query)}&country=us`;
        response = await fetch(fallbackUrl);
        data = await response.json();
      }

      if (data.results && data.results.length > 0) {
        const appInfo = data.results[0];
        res.json({ url: appInfo.trackViewUrl, bundleId: appInfo.bundleId, trackName: appInfo.trackName });
      } else {
        res.status(404).json({ error: "App not found" });
      }
    } catch (error: any) {
      console.error("[API] /api/search-appstore failed:", error);
      res.status(500).json({ error: "Search failed" });
    }
  });

  // API 路由：生成 Hook 代码
  app.post("/api/generate", async (req, res) => {
    const { appName, config } = req.body;
    
    // 增加一个简单的安全判断，如果是 RESEARCH_QUERY 则是研究请求
    const isResearch = appName.startsWith('RESEARCH_QUERY: ');
    const target = isResearch ? appName.replace('RESEARCH_QUERY: ', '') : appName;

    const codeBlockObjC = '```' + 'objective-c';
    const codeBlockMakefile = '```' + 'makefile';
    const codeBlockGeneric = '```';

    const prompt = isResearch 
      ? `你是一位 iOS 逆向工程专家。请用中文详细回答关于 iOS 应用内部结构或逆向工程的以下问题：${target}。重点关注类名、方法名以及使用 Logos 或 Frida 的 hook 策略。`
      : `Role: 你是一位顶尖 iOS 逆向安全专家，精通 LLDB 调试、Cycript 分析及主流广告 SDK 架构。

Task: 请针对特定的 iOS 应用执行去广告分析，并生成基于 Theos/Logos 语法的 .xm 源代码。

目标应用 (或 Bundle ID / AppStore ID)：${target}

Requirements:
${TWEAK_REQUIREMENTS}

交付物：
1. 完整的 Tweak.xm 代码（必须放在 ${codeBlockObjC} 代码块内）。
2. 对应的 Makefile 配置（必须放在 ${codeBlockMakefile} 代码块内，必须设置 \`ARCHS = arm64 arm64e\`）。
3. 简述使用 frida-trace 确认类名的命令。

Language: 所有输出、代码注释及逻辑分析均使用中文。
**绝对禁令：**
1. 代码块 (${codeBlockGeneric}) 内部严禁出现裸露中文说明或 ## 标题！
2. 生成的 .xm 代码必须符合 Theos 语法，%hook 与 %end 必须严格成对！严禁出现多余的 %end（dangling %end）。如果是 @interface ... @end，也必须严格成对。`;

    try {
      await handleAIRequest(prompt, config, res);
    } catch (err: any) {
      console.error(`[API] /api/generate failed for: ${appName} | Error: ${err.message}`);
      res.status(500).json({ error: `生成失败: ${err.message}` });
    }
  });

  // API 路由：对话式修改 Hook 代码
  app.post("/api/modify", async (req, res) => {
    const { appName, currentCode, userPrompt, config } = req.body;
    
    const codeBlockObjC = '```' + 'objective-c';
    const codeBlockMakefile = '```' + 'makefile';
    const codeBlockGeneric = '```';

    const prompt = `Role: 你是一位顶尖 iOS 逆向安全专家，精通 Theos/Logos 语法。
Task: 之前的会话中生成了用于 iOS 逆向的 Tweak.xm 源代码。现在用户要求对代码进行修改或添加新功能。请根据现有的代码和用户最新的要求，提供修改后完整的最新版本代码和对应 Makefile。

目标应用 (或 Bundle ID / AppStore ID)：${appName}
用户的修改要求：${userPrompt}
目前现有的源码上下文：${currentCode}

编码约束 (Strict Constraints):
${TWEAK_REQUIREMENTS}

交付物：
1. 完整的最新的 Tweak.xm 代码 (必须放在 ${codeBlockObjC} 代码块内)。
2. 对应的 Makefile 配置 (必须放在 ${codeBlockMakefile} 代码块内，必须包含 \`ARCHS = arm64 arm64e\`)。
3. 简述所做修改。
Language: 所有输出、代码注释及逻辑分析均使用中文。
**绝对禁令：**
1. 代码块 (${codeBlockGeneric}) 内部严禁出现裸露中文说明或 ## 标题！
2. 修改后的 .xm 代码必须也是完整的，并且 %hook 与 %end 必须严格闭造成对，切忌出现悬空或多余的 %end。`;

    try {
      await handleAIRequest(prompt, config, res);
    } catch (err: any) {
      console.error(`[API] /api/modify failed for: ${appName} | Error: ${err.message}`);
      res.status(500).json({ error: `修改失败: ${err.message}` });
    }
  });

  // API 路由：执行编译 (Simulated or triggered via GitHub)
  app.post("/api/build", async (req, res) => {
    try {
      const { code, appName } = req.body;
      if (!code) {
        return res.status(400).json({ error: "No code provided" });
      }
      // 在这个演示或特定环境下，编译行为通常由 github-push 触发后续 Actions
      // 我们这里返回成功，告知前端逻辑已正确收悉
      console.log(`[API] Build requested for ${appName}`);
      res.json({ status: "success", message: "Build initiated successfully." });
    } catch (error: any) {
      res.status(500).json({ status: "error", error: error.message });
    }
  });

  function cleanupLogosCode(text: string): string {
    return text.replace(/```objective-c([\s\S]*?)```/gi, (match, code) => {
      // Extract all hooked classes
      const hookMatches = [...code.matchAll(/%hook\s+([a-zA-Z0-9_]+)/g)];
      const hookedClasses = new Set(hookMatches.map((m: any) => m[1]));

      // Clean up %init(...)
      let newCode = code.replace(/%init\s*\(([\s\S]*?)\)\s*;/g, (initMatch: string, initContent: string) => {
        if (!initContent.includes('=')) {
          return initMatch;
        }
        
        const parts = initContent.split(',').map((p: string) => p.trim());
        const validParts = parts.filter((part: string) => {
           const classNameMatch = part.match(/^([a-zA-Z0-9_]+)\s*=/);
           if (classNameMatch) {
              const className = classNameMatch[1];
              return hookedClasses.has(className);
           }
           return true; 
        });
        
        if (validParts.length > 0) {
           return '%init(' + validParts.join(', ') + ');';
        } else {
           return '// 被 WebUI 自动过滤: 移除了未提供 %hook 的无意义 %init 赋值防报错';
        }
      });
      
      // Auto-cast self.view to avoid "property 'view' not found on object of type 'id'"
      newCode = newCode.replace(/(?<!\)\s*)self\.view(?=[^A-Za-z0-9_])/g, '((UIViewController *)self).view');
      newCode = newCode.replace(/(?<!\)\s*)self\.presentingViewController/g, '((UIViewController *)self).presentingViewController');
      newCode = newCode.replace(/(?<!\)\s*)self\.removeFromSuperview/g, '[(UIView *)self removeFromSuperview]');
      
      return '```objective-c\n' + newCode.trim() + '\n```';
    });
  }

  async function handleAIRequest(prompt: string, config: any, res: any) {
    const aiProvider = config.provider || process.env.AI_PROVIDER || 'gemini';
    const apiKey = config.apiKey || (aiProvider === 'openai' ? process.env.OPENAI_API_KEY : process.env.GEMINI_API_KEY);
    const modelName = config.modelName || process.env.AI_MODEL || (aiProvider === 'openai' ? 'gpt-4' : 'gemini-1.5-flash');
    const rawBaseUrl = config.baseUrl || process.env.OPENAI_BASE_URL || 'https://api.openai.com/v1';
    const baseUrl = rawBaseUrl.replace(/\/+$/, ''); // 移除末尾所有斜杠防止拼接错误

    if (!apiKey) {
      throw new Error("API Key 未配置。请检查前端设置或服务器 .env 文件。");
    }

    if (aiProvider === 'gemini') {
      const ai = new GoogleGenAI({ apiKey });
      const response = await (ai as any).models.generateContent({
        model: modelName === 'gemini-1.5-flash' ? 'gemini-3.1-pro-preview' : modelName,
        contents: prompt
      });
      const resultText = response.text || "";
      res.json({ explanation: "生成成功", code: cleanupLogosCode(resultText) });
    } else {
      const resp = await fetch(`${baseUrl}/chat/completions`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': apiKey.startsWith('Bearer ') ? apiKey : `Bearer ${apiKey}`
        },
        body: JSON.stringify({
          model: modelName,
          messages: [{ role: 'user', content: prompt }],
          stream: false,
          response_format: { type: "json_object" }
        })
      });
      
      const rawText = await resp.text();
      if (!resp.ok) throw new Error(`AI Provider 报错 (HTTP ${resp.status}): ${rawText.substring(0, 100)}`);

      let data;
      try {
        data = JSON.parse(rawText);
      } catch (e) {
        throw new Error("AI 服务返回非 JSON 格式。");
      }

      const content = data.choices[0]?.message?.content || "";
      let result;
      try {
        let jsonStr = content.trim();
        if (jsonStr.startsWith('```json')) jsonStr = jsonStr.replace(/^```json\n?/, '').replace(/\n?```$/, '');
        result = JSON.parse(jsonStr);
      } catch (e) {
        const codeMatch = content.match(/```(?:obj-cpp|objective-c|cpp)?\s*([\s\S]*?)```/);
        result = {
          explanation: content.split('```')[0].trim() || "生成完毕",
          code: codeMatch ? codeMatch[1].trim() : content.trim()
        };
      }

      if (result.code) result.code = cleanupLogosCode(result.code);
      res.json(result);
    }
  }

  // API 路由：获取可用模型列表
  app.post("/api/ai-models", async (req, res) => {
    const { config } = req.body;
    const aiProvider = config.provider || 'gemini';
    const apiKey = config.apiKey;
    const baseUrl = config.baseUrl || 'https://api.openai.com/v1';

    if (!apiKey) {
      return res.status(400).json({ error: "API Key 未设置" });
    }

    try {
      if (aiProvider === 'gemini') {
        // Gemini 的 SDK 列表获取复杂，这里返回常用模型列表
        res.json({ models: ['gemini-1.5-flash', 'gemini-1.5-pro', 'gemini-2.0-flash-exp'] });
      } else {
        const response = await fetch(`${baseUrl}/models`, {
          headers: { 'Authorization': `Bearer ${apiKey}` }
        });
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        const data = await response.json();
        const models = data.data?.map((m: any) => m.id) || [];
        res.json({ models });
      }
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  });

  // API 路由：测试 AI 连接
  app.post("/api/ai-test", async (req, res) => {
    const { config } = req.body;
    const prompt = "Hi, reply only with 'Connection Successful' in Chinese if you can hear me.";
    
    try {
      // 复用已有的 handleAIRequest 逻辑，但拦截输出
      const aiProvider = config.provider || 'gemini';
      const apiKey = config.apiKey;
      const modelName = config.modelName || (aiProvider === 'openai' ? 'gpt-4' : 'gemini-1.5-flash');
      const baseUrl = config.baseUrl || 'https://api.openai.com/v1';

      if (!apiKey) throw new Error("API Key 未设置");

      if (aiProvider === 'gemini') {
        const ai = new GoogleGenAI({ apiKey });
        // 使用与 handleAIRequest 一致的调用方式避免类型错误
        const response: any = await (ai as any).models.generateContent({
          model: modelName === 'gemini-1.5-flash' ? 'gemini-3.1-pro-preview' : modelName,
          contents: prompt
        });
        res.json({ success: true, message: response.text || "Connection OK" });
      } else {
        const response = await fetch(`${baseUrl}/chat/completions`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${apiKey}`
          },
          body: JSON.stringify({
            model: modelName,
            messages: [{ role: 'user', content: prompt }],
            stream: false
          })
        });
        const data = await response.json();
        if (!response.ok) throw new Error(data.error?.message || `HTTP ${response.status}`);
        res.json({ success: true, message: data.choices[0]?.message?.content });
      }
    } catch (err: any) {
      res.status(500).json({ error: err.message });
    }
  });

  // API 路由：推送到 GitHub
  app.post("/api/github-push", async (req, res) => {
    let { token, owner, repo, content, appName, bundleId, tweakVersion } = req.body;

    // 允许从环境变量读取 Token，如果前端没传
    token = token || process.env.GITHUB_TOKEN;
    owner = owner || "shine85";
    repo = repo || "iosTweak";

    if (!token) {
      return res.status(400).json({ error: "GitHub Token 未设置，请在设置面板配置或检查服务器环境变量。" });
    }
    
    // 提取纯 Tweak.xm 代码
    let tweakContent = content;
    const objcMatch = content.match(/```(?:objective-c|objectivec|objc|c|cpp|c\+\+)?\n([\s\S]*?)```/im);
    if (objcMatch) {
      // 找到第一个看起来像 Tweak 的代码块
      tweakContent = objcMatch[1];
    } else {
      // 如果没有特定的 objective-c 标记，尝试找包含 %hook 的代码块
      const allBlocks = [...content.matchAll(/```[a-zA-Z]*\n([\s\S]*?)```/gim)];
      const hookBlock = allBlocks.find(b => b[1].includes('%hook'));
      if (hookBlock) {
        tweakContent = hookBlock[1];
      }
    }
    
    // 如果提取出的 tweakContent 还是包含 markdown (极端情况保护)
    tweakContent = tweakContent.replace(/^```[a-zA-Z]*\n/m, '').replace(/```$/m, '');
    
    // 强制清洗逻辑：剔除所有以 ## 或 ### 开头的 Markdown 标题行，以及可能残留的 Objective-C 代码块标记
    tweakContent = tweakContent.split('\n').filter(line => {
      const trimmed = line.trim();
      if (trimmed === '') return true; // 保留空行

      // 1. 排除所有的 Markdown 分割线 (---, ***, ___)
      if (/^([-*_])\1{2,}$/.test(trimmed)) {
          return false;
      }

    // 2. 排除 Markdown 标题：只要是以 # 开头但不是标准的预处理指令，一律干掉
    if (trimmed.startsWith('#')) {
      const lower = trimmed.toLowerCase();
      // 这里的指令必须非常严格
      const validDirectives = ['#import', '#define', '#if', '#else', '#elif', '#endif', '#pragma', '#error', '#warning', '#include', '#undef', '#line', '#ifdef', '#ifndef'];
      if (!validDirectives.some(d => lower.startsWith(d))) {
        return false;
      }
    }

    // 4. 彻底解决 NSClassFromString 重定义冲突：剔除可能误报的 @class 声明
    if (trimmed.startsWith('@class') && trimmed.includes('NSClassFromString')) {
        // 如果一行中只包含 NSClassFromString，直接干掉；如果包含多个，剔除掉那个有毒的
        if (trimmed.includes(',')) {
            line = line.replace(/,\s*NSClassFromString\b/g, '').replace(/\bNSClassFromString\s*,\s*/g, '');
        } else {
            return false;
        }
    }
    
    // 3. 排除可能残留的 Markdown 代码块标记（AI 偶尔会嵌套）
      if (trimmed.startsWith('```')) {
          return false;
      }

      return true;
    }).join('\n');
    
    // 替换全角标点符号 (Unicode Homoglyphs) 防止编译报错
    tweakContent = tweakContent.replace(/[\uff08]/g, '(').replace(/[\uff09]/g, ')');

    // 获取 Makefile (如果 AI 也生成了 Makefile 代码块)
    let makefileContent = null;
    const makefileMatch = content.match(/```makefile\n([\s\S]*?)```/im);
    if (makefileMatch) {
      makefileContent = makefileMatch[1];
    }

    // 清洗应用名称用于 Makefile 和 Package ID
    // 先将中文转换成不带声调的拼音
    const pinyinName = pinyin(appName, { toneType: 'none', type: 'array' }).join('');
    
    // 生成安全的文件名和包名
    const safeName = pinyinName.replace(/[^a-zA-Z0-9]/g, '');
    const finalSafeName = safeName || 'Tweak' + Math.random().toString(36).substring(2, 6);
    
    // 生成合法的包名标识
    const safePackageName = pinyinName.replace(/[^a-zA-Z0-9.]/g, '').toLowerCase();
    const finalSafePkg = safePackageName || 'tweak' + Math.random().toString(36).substring(2, 6);

    const date = new Date().toISOString().split('T')[0].replace(/-/g, '');
    const timestamp = Math.floor(Date.now() / 1000);
    const historyPath = `history/${finalSafeName}_${date}_${timestamp}.xm`;

    try {
      const getFile = async (path: string) => {
        const res = await fetch(`https://api.github.com/repos/${owner}/${repo}/contents/${path}`, {
          headers: { 'Authorization': `token ${token}` }
        });
        return res.ok ? await res.json() : null;
      };

      const updateFile = async (path: string, content: string, message: string, sha?: string) => {
        const body: any = {
          message,
          content: Buffer.from(content).toString('base64'),
        };
        if (sha) body.sha = sha;
        const res = await fetch(`https://api.github.com/repos/${owner}/${repo}/contents/${path}`, {
          method: 'PUT',
          headers: { 'Authorization': `token ${token}`, 'Content-Type': 'application/json' },
          body: JSON.stringify(body)
        });
        if (!res.ok) {
          const err = await res.text();
          console.error(`Update ${path} failed:`, err);
          throw new Error(`Failed to update ${path}: ${err}`);
        }
        return await res.json();
      };

      const deleteFile = async (path: string, sha: string, message: string) => {
        const res = await fetch(`https://api.github.com/repos/${owner}/${repo}/contents/${path}`, {
          method: 'DELETE',
          headers: { 'Authorization': `token ${token}`, 'Content-Type': 'application/json' },
          body: JSON.stringify({ message, sha })
        });
        return res.ok;
      };

      // 1. 确保自动化编译流程文件存在且最新 (先清理旧脚本，防止 v3 打包错误)
      // 检查并删除旧版 ios-build.yml
      const legacyPath = '.github/workflows/ios-build.yml';
      const legacyFile = await getFile(legacyPath);
      if (legacyFile?.sha) {
        console.log("Removing legacy workflow...");
        await deleteFile(legacyPath, legacyFile.sha, "Remove legacy iOS build workflow (v3)");
      }

      const workflowPath = '.github/workflows/build.yml';
      const localWorkflow = await fs.readFile(path.join(process.cwd(), workflowPath), 'utf-8');
      const remoteWorkflow = await getFile(workflowPath);
      console.log(`Syncing workflow to GitHub... (SHA: ${remoteWorkflow?.sha || 'new'})`);
      await updateFile(workflowPath, localWorkflow, "Sync Build Automation Workflow (v5)", remoteWorkflow?.sha);

      // 同步清理脚本
      const cleanupPath = '.github/workflows/cleanup.yml';
      try {
        const localCleanup = await fs.readFile(path.join(process.cwd(), cleanupPath), 'utf-8');
        const remoteCleanup = await getFile(cleanupPath);
        await updateFile(cleanupPath, localCleanup, "Sync Cleanup Workflow", remoteCleanup?.sha);
      } catch (e) {
        console.warn("Optional cleanup sync failed:", e);
      }

      // 同步 Makefile 和 control
      const syncFile = async (filename: string, transform?: (c: string) => string) => {
        try {
          let localContent = await fs.readFile(path.join(process.cwd(), filename), 'utf-8');
          if (transform) localContent = transform(localContent);
          const remoteFile = await getFile(filename);
          await updateFile(filename, localContent, `Sync ${filename}`, remoteFile?.sha);
        } catch (e) {
          console.warn(`Optional sync failed for ${filename}:`, e);
        }
      };

      await syncFile('Makefile', (c) => {
        let updated = makefileContent || c;
        const currentNameMatch = updated.match(/^TWEAK_NAME\s*=\s*(.*?)\s*$/m);
        const currentName = currentNameMatch ? currentNameMatch[1] : 'MyTweak';
        
        let newContent = updated.replace(/^TWEAK_NAME\s*=\s*.*$/m, `TWEAK_NAME = ${finalSafeName}`);
        if (currentName !== finalSafeName) {
            newContent = newContent
                .replace(new RegExp(`${currentName}_FILES`, 'g'), `${finalSafeName}_FILES`)
                .replace(new RegExp(`${currentName}_CFLAGS`, 'g'), `${finalSafeName}_CFLAGS`)
                .replace(new RegExp(`${currentName}_CCFLAGS`, 'g'), `${finalSafeName}_CCFLAGS`)
                .replace(new RegExp(`${currentName}_CXXFLAGS`, 'g'), `${finalSafeName}_CXXFLAGS`)
                .replace(new RegExp(`${currentName}_LDFLAGS`, 'g'), `${finalSafeName}_LDFLAGS`)
                .replace(new RegExp(`${currentName}_FRAMEWORKS`, 'g'), `${finalSafeName}_FRAMEWORKS`)
                .replace(new RegExp(`${currentName}_LIBRARIES`, 'g'), `${finalSafeName}_LIBRARIES`);
        }
        return newContent;
      });
      await syncFile('control', (c) => {
        let updated = c.replace(/^Name:.*$/m, `Name: ${appName}`).replace(/^Package:.*$/m, `Package: com.yourcompany.${finalSafePkg}`);
        if (tweakVersion) {
          if (/^Version:.*$/m.test(updated)) {
            updated = updated.replace(/^Version:.*$/m, `Version: ${tweakVersion}`);
          } else {
            updated += `\nVersion: ${tweakVersion}`;
          }
        }
        return updated;
      });

      // 同步工作流文件
      try {
        let workflowContent = await fs.readFile(path.join(process.cwd(), '.github/workflows/build.yml'), 'utf-8');
        const remoteWorkflow = await getFile('.github/workflows/build.yml');
        await updateFile('.github/workflows/build.yml', workflowContent, `Sync build workflow`, remoteWorkflow?.sha);
      } catch (e) {
        console.warn("Workflow sync failed:", e);
      }

      // 1.5 同步 Plist 过滤器
      try {
        let targetBundleId = bundleId;
        if (!targetBundleId) {
            if (/^[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+$/i.test(appName.trim()) || /^[a-zA-Z0-9-]+\.[a-zA-Z0-9-]+$/i.test(appName.trim())) {
                targetBundleId = appName.trim();
            } else {
                targetBundleId = 'com.apple.springboard';
            }
        }
        const plistContent = `{ Filter = { Bundles = ( "${targetBundleId}" ); }; }`;
        const remotePlist = await getFile(`${finalSafeName}.plist`);
        await updateFile(`${finalSafeName}.plist`, plistContent, `Sync ${finalSafeName}.plist`, remotePlist?.sha);
      } catch (e) {
        console.warn("Plist sync failed:", e);
      }

      // 2. 更新主 Tweak.xm (这通常是触发点)
      const tweakFile = await getFile('Tweak.xm');
      await updateFile('Tweak.xm', tweakContent, `Update Tweak for ${appName}`, tweakFile?.sha);

      // 3. 写入历史记录文件
      await updateFile(historyPath, tweakContent, `History: ${appName} build`);

      res.json({ success: true, historyPath });
    } catch (error: any) {
      console.error("GitHub Push Error:", error);
      res.status(500).json({ error: error.message });
    }
  });

  // 核心：处理静态文件和 SPA 路由
  if (process.env.NODE_ENV !== "production") {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    // 强制使用绝对路径确保在 Docker/宝塔中能找到文件
    const distPath = path.resolve(__dirname, 'dist');
    console.log(`[Static] Serving files from: ${distPath}`);
    app.use(express.static(distPath));
    app.get('*', (req, res) => {
      res.sendFile(path.join(distPath, 'index.html'));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`Server running on http://0.0.0.0:${PORT}`);
  });
}

startServer();
