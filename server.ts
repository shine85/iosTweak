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

  // 共享的 Tweak 生成需求指令集 (v1.1.98 强化终极版)
  const TWEAK_REQUIREMENTS = `
目标实体规范（极度重要）：
- 逻辑归一化：不论用户提供的目标是官方应用名、Bundle ID 还是 App Store ID，必须解析为标准的包体特征，并生成全面准确的去除广告逻辑。
- 绝不半吊子 (NO HALF-BAKED CODE & NO LAZINESS)：你的目标是【一次对话，彻底终结所有广告】！绝对不允许给出一个“骨架代码”，或是仅仅给一两个方法然后说“如果还有请自行添加”。你必须把自己当作顶尖逆向安全专家，把你能想到的该 App 可能用到的主流及变种广告 SDK、内部全量弹窗框架全部写出代码。

深度去广告与各类广告满级拦截策略（极其关键 & 核心任务）：
- **全方位大满贯绝杀（用户痛点极高，零容忍需反复催促）(CRITICAL)**：当用户要求“去广告”、“去开屏及进入后的广告”时，你必须在首次回答时直接砸出“无死角终极全家桶”。
  这必须立刻涵盖：1. 开屏(Splash)；2. 各种插屏、弹窗(Interstitial/Popup)；3. Banner/信息流/横幅。你要预判式地把 CSJ/BU (穿山甲), GDT (广点通), KSAd (快手), BaiduMobAd (百度), AdMob, PAG, Sigmob, Mintegral 等全家桶的绝杀 Hook 全部垒进代码！
- **开屏广告 (Splash Ads) 必须根除**：通用防漏网 Hook \`GDTSplashAd\`, \`CSJSplashAd\`, \`BUMNativeSplash\`, \`BUSplashAdView\`, \`BUSplashZoomOutView\`, \`BaiduMobAdSplash\`, \`KSAdSplashViewController\`, \`PAGLAppOpenAd\`, \`ABUSplashAd\` 的展示与请求方法 (\`loadAd\`, \`showAdInWindow:\`等) 并直接 nil / 阻断。
- **弹窗与插屏广告 (Interstitial/Popup Ads) 必须根除**：必须显式拦截各类插屏广告基类，如 \`GDTUnifiedInterstitialAd\`, \`BUInterstitialAd\`, \`BUNativeExpressInterstitialAd\`, \`CSJInterstitialAd\`, \`KSInterstitialAd\`, \`KSAdInterstitialViewController\`, \`BaiduMobAdInterstitial\` 的展示方法，以及应用内各类的 \`RewardVideoAd\` 或 \`xPopupAd\` 或动态生成的 \`MarketingDialog\`。
- **全局浮窗拦截与大杀器兜底**：必须双重兜底。全局 Hook \`UIWindow\` 的 \`makeKeyAndVisible\`、\`becomeKeyWindow\` 和 \`setHidden:\`，发现 \`SplashWindow\`, \`AdWindow\`, \`PAGWindow\` 或包含 \`Ad\` 的可疑弹窗直接调用 \`%orig(YES)\` 或 \`%orig(NO)\` 阻断。全局 Hook \`UIViewController\` 的 \`viewWillAppear:\` 判断带 \`Interstitial\`, \`Bidding\`, \`Reward\`, \`Popup\` 的广告类强制 \`dismiss\` 并隐藏 view。
- **防止白屏、黑屏零容忍 (CRITICAL 防死锁规则)**：干掉广告不是结束，干掉广告却让用户黑屏是你的罪过！1. 杀开屏 Window 时务必让主 Window 抢占 KeyWindow；2. 拦截带有 delegate 的广告展示时，必须必须伪造 \`splashAdClosed:\`, \`splashAdDidDismiss:\`, \`nativeExpressInterstitialAdDidClose:\`, \`interstitialAdDidClose:\` 抛回给发帖人。
- **视图层强杀与编译红线**：拦截 \`UIViewController\` 或 \`UIView\` 时，“点语法”是编译死敌。严禁写 \`self.view\`，必须强转为 \`((UIViewController *)self).view\` 或使用 \`performSelector:\`。
- **误伤绝对防护**：使用 \`NSStringFromClass([self class])\` 匹配时，只能拦带 \`SplashAd\`, \`PAGL\`, \`AdView\` 等后缀的广告类，绝对禁止拦截 \`Home\`、\`CM\`、\`Main\` 等短词防止应用白屏！

应用特定逻辑参考：
- **TikTok/抖音**：Hook \`AWEFeedAdModel\`, \`BDASplashManager\`。
- **WeChat/微信**：Hook \`WCBizMainViewController\`, \`MMUIViewController\` 的相关显示逻辑。
- **国内核心应用（移动联通电信、大型平台等）**：拦截特定的 \`SplashManager\`, \`AdSplashView\`，以及极喜欢用的 \`PopupManager\`, \`AdPopup\`, \`MarketingPopup\`。

代码实现 (Logos)：
- **单次 Hook 初始化约束**：在同一个 %group 中，绝不允许出现超过一次的 \`%init\`。如果是未知类必须用带赋值的语法，如 \`%init(ClassA=objc_getClass("ClassA"));\`。严禁 \`%init(ClassName);\` 防止致命报错。
- **未知类初始化防崩约束**：你所 hook 的每一个类（甚至是全局兜底的类），必须在顶部使用 \`@interface ClassName : UIView @end\`(或 \`UIViewController\`/ \`NSObject\`) 声明，防止因为 forward declaration 导致编译爆炸！千万不要只写一个 \`@class\`！
- **%init 位置约束**：所有的 \`%init\` 必须放在 \`%ctor\` 构造块内部！绝对不要在外部全局调用 \`%init;\`。
- **Hook 语法约束**：在 Hook 带有参数的 Objective-C 方法时，**绝对禁止**在参数名称后面添加多余的右括号 \`)\`。
- **C 函数规范约束**：严禁在 \`%ctor\` 等函数体/Block 内部直接定义 C/C++ 辅助函数。辅助函数必须放在文件顶层全局作用域。
- **常用辅助函数库 (Common Helpers)**：
  - 如果你需要遍历恢复视图，**必须**使用以下标准实现（放在文件顶部）：
    \`static void forceRestoreSubViews(UIView *view) { if(!view) return; for(UIView *sub in view.subviews) { sub.hidden = NO; sub.alpha = 1.0; if(sub.subviews.count > 0) forceRestoreSubViews(sub); } }\`
- **对象属性点语法崩溃约束**：在作用域内，**绝对禁止使用点语法**读取属性。必须写为 \`((UIViewController *)self).presentingViewController\` 或是 \`((UIViewController *)self).view.hidden = YES;\`。
- **类名传参安全防范**：往 C 函数传类名参数时，若是字符串用双引号，若是 Class 用 \`objc_getClass("ClassName")\`。绝对禁止裸传类名。
- **安全拦截与防白屏 (CRITICAL)**：代理回调的正确操作（提取 delegate 用 performSelector，千万别用 \`self.delegate\`）：
    \`#pragma clang diagnostic push\`
    \`#pragma clang diagnostic ignored "-Warc-performSelector-leaks"\`
    \`if ([self respondsToSelector:@selector(delegate)]) { id delegate = [self performSelector:@selector(delegate)]; if ([delegate respondsToSelector:@selector(splashAdClosed:)]) { [delegate performSelector:@selector(splashAdClosed:) withObject:self]; } else if ([delegate respondsToSelector:@selector(splashAdDidDismissFullScreenContent:)]) { [delegate performSelector:@selector(splashAdDidDismissFullScreenContent:) withObject:self]; } else if ([delegate respondsToSelector:@selector(interstitialAdDidClose:)]) { [delegate performSelector:@selector(interstitialAdDidClose:) withObject:self]; } else if ([delegate respondsToSelector:@selector(splashDidDismissScreen:)]) { [delegate performSelector:@selector(splashDidDismissScreen:) withObject:self]; } }\`
    \`#pragma clang diagnostic pop\`
    \`if ([self isKindOfClass:[UIView class]]) { [(UIView *)self setHidden:YES]; [((UIView *)self) removeFromSuperview]; }\`
    \`else if ([self isKindOfClass:[UIViewController class]]) { [((UIViewController *)self) dismissViewControllerAnimated:NO completion:nil]; }\`
- **架构与版本注入支持**：生成的 Makefile 必须包含 \`ARCHS = arm64 arm64e\`。同时**必须配置版本号注入**，即在 Makefile 中加入 \`$(TWEAK_NAME)_LDFLAGS += -Wl,-current_version,1.0.0\`（1.0.0 可以替换为你设定的版本或宏）。这非常重要，否则 TrollFools 无法识别注入版本！
- **基石依赖**：所有 Hook 必须确保引入相应的 Foundation 框架类型定义，使用 \`MSHookMessageEx\` 必须 \`#import <substrate.h>\`。
- **注入生命周期证明**：在 Tweak.xm 文件中，全局 Hook \`UIApplication\` 的 \`-[UIApplication applicationDidFinishLaunching:]\` 或 \`application:didFinishLaunchingWithOptions:\` 方法，添加一个日志输出 \`NSLog(@"[!!!] Tweak 注入成功");\`，表明插件已成功注入。
- **模板化广告拦截**：必须为常见的广告 SDK（如穿山甲 CSJ, 广点通 GDT 的各类开屏及插屏类如 \`BUSplashAdView\`, \`GDTSplashAd\` 等）编写一个通用的 Logos Hook 模板，拦截其加载和显示方法，并返回 nil 或 nil-equivalent 防止展示。
- **配置与依赖完整性**：
  1. 需要给出 \`control\` 文件的配置示例（Name, Version, Author, Maintainer 字段），Version 字段必须是合理的版本号且与 Makefile 或构建体系的版本号保持一致。
  2. 根据目标 App 的 Bundle ID，提供正确的 \`Filter.plist\` 内容示例，例如 \`Filter = { Bundles = ( "com.target.bundleId" ); };\`。
  3. Makefile 中**必须添加基础框架依赖**：确保包含 \`$(TWEAK_NAME)_FRAMEWORKS = Foundation UIKit\`。

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
    // If the text is wrapped in markdown, extract it first
    let innerCode = text;
    let hasWrapper = false;
    const match = text.match(/```(?:objective-c|objc)?\s*\n([\s\S]*?)```/im) || text.match(/```\s*\n([\s\S]*?)```/im);
    if (match) {
        innerCode = match[1];
        hasWrapper = true;
    }

    // Extract all hooked classes
    const hookMatches = [...innerCode.matchAll(/%hook\s+([a-zA-Z0-9_]+)/g)];
    const hookedClasses = new Set(hookMatches.map((m: any) => m[1]));

    // Clean up %init(...)
    let newCode = innerCode.replace(/%init\s*\(([\s\S]*?)\)\s*;/g, (initMatch: string, initContent: string) => {
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
    
    // Auto-cast self.view
    newCode = newCode.replace(/(?<!\)\s*)self\.view(?=[^A-Za-z0-9_])/g, '((UIViewController *)self).view');
    newCode = newCode.replace(/(?<!\)\s*)self\.presentingViewController/g, '((UIViewController *)self).presentingViewController');
    newCode = newCode.replace(/(?<!\)\s*)self\.removeFromSuperview/g, '[(UIView *)self removeFromSuperview]');
    
    // Note: since our app expects the bare code to render in ReactMarkdown, we just return the raw code.
    // Ensure we don't accidentally re-wrap if it didn't have one, or strip it if the frontend needs but wait!
    // The frontend wraps it itself: {`\`\`\`objective-c\n${generatedResult}\n\`\`\``}
    // So we MUST return unwrapped raw code here.
    return newCode.trim();
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
      
      let exp = "代码生成完成。";
      let extraction = resultText;
      
      let parts = resultText.split(/```(?:objective-c|objectivec|objc|c|cpp|c\+\+)?\n/i);
      if (parts.length < 2) {
        parts = resultText.split(/```[a-zA-Z]*\n/i);
      }
      
      if (parts.length > 1) {
        const beforeCode = parts[0].trim();
        const afterSplit = parts[1].split('```');
        const codePart = afterSplit[0];
        const afterCode = afterSplit.slice(1).join('```').trim();
        
        if (beforeCode) {
          exp = beforeCode;
          if (afterCode) {
            exp += '\n\n' + afterCode;
          }
        } else if (afterCode) {
          exp = afterCode;
        }
        
        extraction = codePart;
      }
      
      let cleaned = cleanupLogosCode(extraction.trim());
      
      res.json({ explanation: exp, code: cleaned });
    } else {
      const fetchUrl = baseUrl.endsWith('/chat/completions') ? baseUrl : `${baseUrl}/chat/completions`;
      const resp = await fetch(fetchUrl, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': apiKey.startsWith('Bearer ') ? apiKey : `Bearer ${apiKey}`
        },
        body: JSON.stringify({
          model: modelName,
          messages: [{ role: 'user', content: prompt }],
          stream: false
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
      
      let exp = "代码生成完成。";
      let extraction = content;
      
      let parts = content.split(/```(?:objective-c|objectivec|objc|c|cpp|c\+\+)?\n/i);
      if (parts.length < 2) {
        parts = content.split(/```[a-zA-Z]*\n/i);
      }
      
      if (parts.length > 1) {
        const beforeCode = parts[0].trim();
        const afterSplit = parts[1].split('```');
        const codePart = afterSplit[0];
        const afterCode = afterSplit.slice(1).join('```').trim();
        
        if (beforeCode) {
          exp = beforeCode;
          if (afterCode) {
            exp += '\n\n' + afterCode;
          }
        } else if (afterCode) {
          exp = afterCode;
        }
        
        extraction = codePart;
      }
      
      let cleaned = cleanupLogosCode(extraction.trim());

      res.json({ explanation: exp, code: cleaned });
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
        const fetchUrl = baseUrl.endsWith('/chat/completions') ? baseUrl.replace(/\/chat\/completions$/, '/models') : `${baseUrl}/models`;
        const response = await fetch(fetchUrl, {
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
        const fetchUrl = baseUrl.endsWith('/chat/completions') ? baseUrl : `${baseUrl}/chat/completions`;
        const response = await fetch(fetchUrl, {
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
