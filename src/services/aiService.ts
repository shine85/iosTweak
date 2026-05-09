import { GoogleGenAI } from "@google/genai";

export interface AIConfig {
  provider: 'gemini' | 'openai';
  apiKey: string;
  baseUrl?: string;
  modelName: string;
  githubToken?: string;
  githubRepo?: string;
}

export async function modifyHookScript(appName: string, currentCode: string, userPrompt: string, config: AIConfig) {
  try {
    const response = await fetch('/api/modify', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ appName, currentCode, userPrompt, config })
    });
    const data = await response.json();
    if (data.error) throw new Error(data.error);
    return data.result;
  } catch (error: any) {
    return `生成错误: ${error.message}`;
  }
}

export async function generateHookScript(appName: string, config: AIConfig) {
  try {
    const response = await fetch('/api/generate', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ appName, config })
    });
    const data = await response.json();
    if (data.error) throw new Error(data.error);
    return data.result;
  } catch (error: any) {
    return `生成错误: ${error.message}`;
  }
}

export async function pushToGithub(content: string, appName: string, config: AIConfig, bundleId?: string) {
  try {
    const [owner, repo] = (config.githubRepo || '').split('/');
    if (!owner || !repo || !config.githubToken) {
      throw new Error("请先在设置中配置 GitHub Token 和 仓库路径 (格式: owner/repo)");
    }

    const response = await fetch('/api/github-push', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        token: config.githubToken,
        owner,
        repo,
        content,
        appName,
        bundleId
      })
    });
    const data = await response.json();
    if (data.error) throw new Error(data.error);
    return data;
  } catch (error: any) {
    throw error;
  }
}

export async function researchMethod(query: string, config: AIConfig) {
  // 同样通过 API 调用或保持前端调用（取决于安全性需求，这里建议统一走后端）
  try {
    const response = await fetch('/api/generate', { // 这里可以复用逻辑，修改 prompt
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ 
        appName: `RESEARCH_QUERY: ${query}`, 
        config 
      })
    });
    const data = await response.json();
    return data.result;
  } catch (error: any) {
    return "获取研究数据失败。";
  }
}

export async function fetchModels(config: AIConfig) {
  try {
    const response = await fetch('/api/ai-models', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ config })
    });
    const data = await response.json();
    if (data.error) throw new Error(data.error);
    return data.models as string[];
  } catch (error: any) {
    throw error;
  }
}

export async function testAIConnection(config: AIConfig) {
  try {
    const response = await fetch('/api/ai-test', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ config })
    });
    const data = await response.json();
    if (data.error) throw new Error(data.error);
    return data.message;
  } catch (error: any) {
    throw error;
  }
}
