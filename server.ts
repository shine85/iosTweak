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
        const genAI = new GoogleGenAI({ apiKey });
        const model = genAI.getGenerativeModel({ model: modelName });
        const result = await model.generateContent(prompt);
        res.json({ result: result.response.text() });
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
    const date = new Date().toISOString().split('T')[0].replace(/-/g, '');
    const timestamp = Math.floor(Date.now() / 1000);
    const historyPath = `history/${appName}_${date}_${timestamp}.xm`;

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

      // 1. 确保自动化编译流程文件存在且最新 (先同步环境再推送代码，防止触发旧版 Action)
      const workflowPath = '.github/workflows/build.yml';
      const localWorkflow = await fs.readFile(path.join(process.cwd(), workflowPath), 'utf-8');
      const remoteWorkflow = await getFile(workflowPath);
      await updateFile(workflowPath, localWorkflow, "Sync Build Automation Workflow (v4)", remoteWorkflow?.sha);

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

      await syncFile('Makefile', (c) => c.replace(/TWEAK_NAME = .*$/m, `TWEAK_NAME = ${appName}`).replace(/MyTweak_FILES/g, `${appName}_FILES`).replace(/MyTweak_CFLAGS/g, `${appName}_CFLAGS`));
      await syncFile('control', (c) => c.replace(/^Name:.*$/m, `Name: ${appName}`).replace(/^Package:.*$/m, `Package: com.yourcompany.${appName.toLowerCase()}`));

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
