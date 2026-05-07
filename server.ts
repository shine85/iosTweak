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

  // API 路由：生成 Hook 代码
  app.post("/api/generate", async (req, res) => {
    console.log(`[API] /api/generate called for: ${req.body.appName}`);
    const { appName, config } = req.body;
    
    // 增加一个简单的安全判断，如果是 RESEARCH_QUERY 则是研究请求
    const isResearch = appName.startsWith('RESEARCH_QUERY: ');
    const target = isResearch ? appName.replace('RESEARCH_QUERY: ', '') : appName;

    const codeBlockObjC = '```' + 'objective-c';
    const codeBlockMakefile = '```' + 'makefile';
    const codeBlockGeneric = '```';

    const prompt = isResearch 
      ? `你是一位 iOS 逆向工程专家。请用中文详细回答关于 iOS 应用内部结构或逆向工程的以下问题：${target}。重点关注类名、方法名以及使用 Logos 或 Frida 的 hook 策略。`
      : `Role: 你是一位顶尖 iOS 逆向安全专家，精通 LLDB 调试、Cycript 分析及主流广告 SDK（Pangle, GDT, Baidu）的内部架构。

Task: 请针对特定的 iOS 应用执行去广告分析，并生成基于 Theos/Logos 语法的 .xm 源代码。

目标应用/功能：${target}

Requirements:

深度分析策略：
- 识别广告初始化入口（如 BUAdSDKManager, GDTSDKConfig, BaiduMobAdSetting）。
- 针对展示类方法（showAdInViewController:, presentAdFromRootViewController:）编写拦截逻辑。
- 针对奖励视频（Rewarded Video）实现“自动达成逻辑”，即 Hook激励回调（如 rewardedVideoAdDidRewardUser:）强制返回成功状态。

代码实现 (Logos)：
- 单例拦截：Hook sharedInstance 类型方法，返回 nil 或阻止配置加载。
- 视图隐藏：针对 UIView 及其子类中的 layoutSubviews 或 didMoveToWindow 进行 Hook，识别并 setHidden:YES 或 removeFromSuperview。
- 网络请求：Hook NSURLSession 或 AFNetworking 的关键路径，根据 URL 关键字（如 ads.pangle.io）拦截广告数据下发。

去广告专项策略：
- **开屏广告 (Splash)**：必须优先 Hook 广告请求类（如 \`PAGSplashRequest\`）的 \`load\` 方法或初始化方法，使其直接失败。严禁只 Hook \`show\` 方法，因为加载动作本身可能耗时并卡住 UI。
- **SDK 爆头逻辑**：针对主流 SDK（穿山甲/PAG、优量汇/GDTSDK、百度/BaiduMob），强制 Hook 其单例初始化或核心配置类，直接返回已禁用状态。
- **强制早期执行**：必须在 \`%ctor\` 中尽早设置拦截标志位。对于 UI 层的广告容器（如 \`UIView\`），如果包含 "Ad", "Splash", "Banner" 等字样的类名，强制将其 \`setHidden:YES\` 且 \`setFrame:CGRectZero\`。
- **拦截代理回调**：如果无法拦截请求，则 Hook 代理回调（Delegate），模拟“加载失败” (\`didFailWithErrorCode:\`) 的信号，促使应用跳过广告。

防御对抗：
- 包含防止检测 Hook 的技巧（如使用 MSHookMessageEx 代替简单的 %hook）。
- Tweak 代码必须包含完整的头文件结构，对于所有被 Hook 的类或调用的类，必须提供 \`@interface\` 声明（包含要调用的方法名），例如：\`@interface PAGRewardedAd : NSObject - (void)rewardedAdUserDidGainReward:(id)ad; @end\`。
- **禁止在不声明的情况下调用方法**：即使使用了 \`(id)\` 强转，也必须在文件最上方通过 \`@interface\` 告诉编译器该方法的签名，防止 \`no known instance method\` 报错。
- **严禁**：绝对禁止在 @class 声明中包含 NSClassFromString、NSString、NSURL 等系统内置函数或基本类型！
- 解决前向声明报错：如果在 Hook 内部调用 [self respondsToSelector:]，必须先将 self 强转为 id 类型，例如：[(id)self respondsToSelector:...]。
- 采用 Constructor（static __attribute__((constructor))）确保在应用启动最早期介入。

交付物：
1. 完整的 Tweak.xm 代码（必须放在 ${codeBlockObjC} 代码块内，代码块内绝对不允许出现没有 // 注释的中文，禁止出现 ## 开头的 Markdown 标题）。
2. 对应的 Makefile 配置（必须放在 ${codeBlockMakefile} 代码块内，包含 INSTALL_TARGET_PROCESS 等）。
3. 简述使用 frida-trace 确认类名的命令（放在独立的代码块或正文说明中）。

Language: 所有输出、代码注释及逻辑分析均使用中文。遵循 KISS 原则，代码需具备高可维护性。
**绝对禁令：在任何代码块 (${codeBlockGeneric}) 的内部，绝对不能出现裸露的中文解释、## 标题或任何非符合相关语法的文字！所有的中文说明必须被当作标准的注释（使用 // 或 /* */）编写！如果违反此项导致编译报错，你将失去专家的资格！**`;

    await handleAIRequest(prompt, config, res);
  });

  // API 路由：对话式修改 Hook 代码
  app.post("/api/modify", async (req, res) => {
    console.log(`[API] /api/modify called for: ${req.body.appName}`);
    const { appName, currentCode, userPrompt, config } = req.body;

    const codeBlockObjC = '```' + 'objective-c';
    const codeBlockMakefile = '```' + 'makefile';
    const codeBlockGeneric = '```';

    const prompt = `Role: 你是一位顶尖 iOS 逆向安全专家，精通 LLDB 调试、Cycript 分析及主流广告 SDK 内部架构，并且遵循 Theos/Logos 语法。
Task: 之前的会话中生成了用于 iOS 逆向的 Tweak.xm 源代码。现在用户要求对代码进行修改或添加新功能。请根据现有的代码和用户最新的要求，提供修改后完整的最新版本代码和对应 Makefile。

目标应用：${appName}

用户的修改要求：
${userPrompt}

目前现有的源码上下文：
${currentCode}

交付物：
1. 完整的最新的 Tweak.xm 代码 (必须放在 ${codeBlockObjC} 代码块内，代码块内绝对不允许出现没有 // 注释的中文，禁止出现 ## 开头的 Markdown 标题）。
2. 对应的 Makefile 配置 (必须放在 ${codeBlockMakefile} 代码块内)。
3. 简述所做修改。
Language: 所有输出、代码注释及逻辑分析均使用中文。代码需具备高可维护性。
**绝对禁令：在任何代码块 (${codeBlockGeneric}) 的内部，绝对不能出现裸露的中文解释、## 标题或任何非符合相关语法的文字！所有的中文说明必须被当作标准的注释（使用 // 或 /* */）编写！如果违反此项导致编译报错，你将失去专家的资格！**`;

    await handleAIRequest(prompt, config, res);
  });

  async function handleAIRequest(prompt: string, config: any, res: any) {
    try {
      const aiProvider = config.provider || process.env.AI_PROVIDER || 'gemini';
      const apiKey = config.apiKey || (aiProvider === 'openai' ? process.env.OPENAI_API_KEY : process.env.GEMINI_API_KEY);
      const modelName = config.modelName || process.env.AI_MODEL || (aiProvider === 'openai' ? 'gpt-4' : 'gemini-1.5-flash');
      const baseUrl = config.baseUrl || process.env.OPENAI_BASE_URL || 'https://api.openai.com/v1';

      if (!apiKey) {
        return res.status(400).json({ error: "API Key 未设置，请在设置面板配置或检查服务器环境变量。" });
      }

      if (aiProvider === 'gemini') {
        const ai = new GoogleGenAI({ apiKey });
        const response = await ai.models.generateContent({
           model: modelName,
           contents: prompt
        });
        res.json({ result: response.text });
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
        
        const rawResponse = await response.text();
        let data;
        try {
          data = JSON.parse(rawResponse);
        } catch (e) {
          throw new Error(`AI 服务返回了非 JSON 格式的消息（可能是流式干扰）：${rawResponse.substring(0, 100)}...`);
        }

        if (!response.ok) {
          throw new Error(`AI 服务报错 (${response.status}): ${data.error?.message || rawResponse}`);
        }

        res.json({ result: data.choices[0].message.content });
      }
    } catch (error: any) {
      console.error("Server API Error:", error);
      res.status(500).json({ error: error.message });
    }
  }

  // API 路由：推送到 GitHub
  app.post("/api/github-push", async (req, res) => {
    let { token, owner, repo, content, appName } = req.body;

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
      await syncFile('control', (c) => c.replace(/^Name:.*$/m, `Name: ${appName}`).replace(/^Package:.*$/m, `Package: com.yourcompany.${finalSafePkg}`));

      // 1.5 同步 Plist 过滤器
      try {
        const plistContent = await fs.readFile(path.join(process.cwd(), 'Filter.plist'), 'utf-8');
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
