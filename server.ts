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

  // 共享的 Tweak 生成需求指令集 (v1.1.42 强化版)
  const TWEAK_REQUIREMENTS = `
目标实体规范（极度重要）：
- 逻辑归一化：不论用户提供的目标是官方应用名（如“中国移动”）、AppStore副标题名称（如“中国移动(手机营业厅)”）、Bundle ID（如“com.greenpoint.android.mc10086.activity”或 iOS 相关 Bundle ID）还是 App Store ID（如“id583700738”），你必须首先在内部推理阶段将其归一化解析为同一对象的标准 Bundle ID 和包体特征。
- 产物一致性：严禁因为输入名称格式不同而导致生成的 Hook 代码、类名猜测或 Makefile 配置不同。本质是同一款 APP，其最终的注入策略与生成产物必须 100% 完全一致。

深度分析策略：
- 针对展示类方法 (showAd..., presentAd...) 实现拦截。
- 自动化跳过：针对激励视频，强制将 \`isReady\` 返回 \`YES\`，并同步触发奖励回调。

应用特定逻辑参考：
- **TikTok/抖音**：Hook \`AWEFeedAdModel\`, \`BDASplashManager\`。
- **WeChat/微信**：Hook \`WCBizMainViewController\`, \`MMUIViewController\` 的相关显示逻辑。
- **Instagram/X (Twitter)/Snapchat 等国外热门应用**：生成明确的 .xm 代码段用于去除信息流广告、视频插入广告等，并预留 \`<#AppSpecificClassName#>\` 或类似占位符供用户填写（如果不确定具体类名）。
- **通用**：识别并拦截 \`PAGSplashRequest\`, \`GDTSplashAd\`。

代码实现 (Logos)：
- **强制早期执行**：必须在 \`%ctor\` 中尽早拦截。
- **架构支持**：生成的 Makefile 必须包含 \`ARCHS = arm64 arm64e\`。
- **基石依赖**：使用 \`MSHookMessageEx\` 必须 \`#import <substrate.h>\`。

防御对抗：
- 必须为所有 Hook 或调用的类提供 \`@interface\` 签名，防止 \`no known instance method\`。
- 严禁在 @class 中包含系统内置类型（如 NSString）。
`;

  // API 路由：搜索 App Store 信息
  app.get("/api/search-appstore", async (req, res) => {
    try {
      const { query } = req.query;
      if (!query) {
        return res.status(400).json({ error: "Missing query parameter" });
      }

      // Check if it's an ID starting with 'id'
      let url = '';
      if (typeof query === 'string' && query.startsWith('id')) {
        const id = query.substring(2);
        url = `https://itunes.apple.com/lookup?id=${id}`;
      } else {
        url = `https://itunes.apple.com/search?term=${encodeURIComponent(String(query))}&entity=software&limit=1`;
      }

      const response = await fetch(url);
      const data = await response.json();

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
**绝对禁令：代码块 (${codeBlockGeneric}) 内部严禁出现裸露中文说明或 ## 标题！**`;

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
**绝对禁令：代码块 (${codeBlockGeneric}) 内部严禁出现裸露中文说明或 ## 标题！**`;

    try {
      await handleAIRequest(prompt, config, res);
    } catch (err: any) {
      console.error(`[API] /api/modify failed for: ${appName} | Error: ${err.message}`);
      res.status(500).json({ error: `修改失败: ${err.message}` });
    }
  });

  async function handleAIRequest(prompt: string, config: any, res: any) {
    const aiProvider = config.provider || process.env.AI_PROVIDER || 'gemini';
    const apiKey = config.apiKey || (aiProvider === 'openai' ? process.env.OPENAI_API_KEY : process.env.GEMINI_API_KEY);
    const modelName = config.modelName || process.env.AI_MODEL || (aiProvider === 'openai' ? 'gpt-4' : 'gemini-1.5-flash');
    const baseUrl = config.baseUrl || process.env.OPENAI_BASE_URL || 'https://api.openai.com/v1';

    if (!apiKey) {
      throw new Error("API Key 未配置。请检查前端设置或服务器 .env 文件。");
    }

    if (aiProvider === 'gemini') {
      const ai = new GoogleGenAI({ apiKey });
      const response = await ai.models.generateContent({
        model: modelName === 'gemini-1.5-flash' ? 'gemini-3.1-pro-preview' : modelName,
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
        throw new Error(`AI 服务返回格式错误 (Raw: ${rawResponse.substring(0, 50)}...)`);
      }

      if (!response.ok) {
        const errorMsg = data.error?.message || `HTTP ${response.status}`;
        throw new Error(`AI Provider 报错: ${errorMsg}`);
      }

      const content = data.choices[0]?.message?.content;
      if (!content) {
        throw new Error("AI 服务未返回有效内容。");
      }

      res.json({ result: content });
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
