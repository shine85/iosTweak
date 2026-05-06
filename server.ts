import express from "express";
import path from "path";
import fs from "fs/promises";
import { fileURLToPath } from "url";
import { GoogleGenAI } from "@google/genai";
import dotenv from "dotenv";
import { createServer as createViteServer } from "vite";

dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

async function startServer() {
  const app = express();
  const PORT = 12300;

  app.use(express.json());

  // API 路由：生成 Hook 代码
  app.post("/api/generate", async (req, res) => {
    const { appName, config } = req.body;
    
    // 增加一个简单的安全判断，如果是 RESEARCH_QUERY 则是研究请求
    const isResearch = appName.startsWith('RESEARCH_QUERY: ');
    const target = isResearch ? appName.replace('RESEARCH_QUERY: ', '') : appName;

    const prompt = isResearch 
      ? `你是一位 iOS 逆向工程专家。请用中文详细回答关于 iOS 应用内部结构或逆向工程的以下问题：${target}。重点关注类名、方法名以及使用 Logos 或 Frida 的 hook 策略。`
      : `为 iOS 应用生成原生的 .dylib 插件代码（基于 Theos/Logos 语法）：${target}。
        要求：
        1. 生成 .xm 文件内容，包含必须的 #import 和 %hook 块。
        2. 针对常见的广告 SDK（如 Pangle/穿山甲、GDT/优量汇、百度广告）编写 Hook 逻辑。
        3. 重点 Hook 初始化方法、展示方法和奖励回调。
        4. 包含对 Tweak 信息和编译设置的中文说明。
        5. 确保是 LOGOS 语法。`;

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
  });

  // API 路由：推送到 GitHub
  app.post("/api/github-push", async (req, res) => {
    const { token, owner, repo, content, appName } = req.body;
    
    // 清洗应用名称用于 Makefile 和 Package ID
    const safeName = appName.replace(/[^a-zA-Z0-9]/g, '') || 'Tweak';
    const safePackageName = appName.replace(/[^a-zA-Z0-9.]/g, '').toLowerCase() || 'tweak';

    const date = new Date().toISOString().split('T')[0].replace(/-/g, '');
    const timestamp = Math.floor(Date.now() / 1000);
    const historyPath = `history/${safeName}_${date}_${timestamp}.xm`;

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

      await syncFile('Makefile', (c) => c.replace(/TWEAK_NAME = .*$/m, `TWEAK_NAME = ${safeName}`).replace(/MyTweak_FILES/g, `${safeName}_FILES`).replace(/MyTweak_CFLAGS/g, `${safeName}_CFLAGS`));
      await syncFile('control', (c) => c.replace(/^Name:.*$/m, `Name: ${appName}`).replace(/^Package:.*$/m, `Package: com.yourcompany.${safePackageName}`));

      // 1.5 同步 Plist 过滤器
      try {
        const plistContent = await fs.readFile(path.join(process.cwd(), 'Filter.plist'), 'utf-8');
        const remotePlist = await getFile(`${safeName}.plist`);
        await updateFile(`${safeName}.plist`, plistContent, `Sync ${safeName}.plist`, remotePlist?.sha);
      } catch (e) {
        console.warn("Plist sync failed:", e);
      }

      // 2. 更新主 Tweak.xm (这通常是触发点)
      const tweakFile = await getFile('Tweak.xm');
      await updateFile('Tweak.xm', content, `Update Tweak for ${appName}`, tweakFile?.sha);

      // 3. 写入历史记录文件
      await updateFile(historyPath, content, `History: ${appName} build`);

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
