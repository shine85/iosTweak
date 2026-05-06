/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

/**
 * @license
 * SPDX-License-Identifier: Apache-2.0
 */

import React, { useState, useEffect } from 'react';
import { 
  Shield, 
  Code2, 
  Search, 
  BookOpen, 
  Zap, 
  Copy, 
  Check, 
  RotateCcw, 
  Smartphone,
  Cpu,
  Layers,
  Terminal,
  ShieldAlert,
  Download,
  Box,
  Wind,
  Bird,
  Settings,
  X,
  LogOut,
  User as UserIcon
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import ReactMarkdown from 'react-markdown';
import rehypeHighlight from 'rehype-highlight';
import { cn } from './lib/utils';
import { generateHookScript, researchMethod, type AIConfig } from './services/aiService';
import { useAuth, logout } from './components/AuthProvider';

type Tab = 'builder' | 'researcher' | 'guides' | 'settings';

export default function App() {
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState<Tab>('builder');
  const [appName, setAppName] = useState('河马剧场');
  const [isGenerating, setIsGenerating] = useState(false);
  const [generatedResult, setGeneratedResult] = useState('');
  const [researchQuery, setResearchQuery] = useState('');
  const [researchResult, setResearchResult] = useState('');
  const [copying, setCopying] = useState<'builder' | 'researcher' | null>(null);

  // AI Configuration State with Persistence
  const [aiConfig, setAiConfig] = useState<AIConfig>(() => {
    const saved = localStorage.getItem('ios_tweak_ai_config');
    if (saved) {
      try {
        return JSON.parse(saved);
      } catch (e) {
        console.error("Parse saved config failed", e);
      }
    }

    const meta = (import.meta as any).env || {};
    const provider = meta.VITE_AI_PROVIDER || 'gemini';
    return {
      provider: provider as any,
      apiKey: (provider === 'openai' ? meta.VITE_OPENAI_API_KEY : meta.VITE_GEMINI_API_KEY) || '',
      baseUrl: meta.VITE_OPENAI_BASE_URL || 'https://api.openai.com/v1',
      modelName: meta.VITE_AI_MODEL || (provider === 'openai' ? 'gpt-4' : 'gemini-1.5-flash'),
      githubToken: '',
      githubRepo: 'shine85/ios--Tweak'
    };
  });

  useEffect(() => {
    localStorage.setItem('ios_tweak_ai_config', JSON.stringify(aiConfig));
  }, [aiConfig]);

  const [isPushing, setIsPushing] = useState(false);

  const handleGenerate = async () => {
    if (!aiConfig.apiKey) {
      alert("请先在设置中配置 API Key");
      setActiveTab('settings');
      return;
    }
    setIsGenerating(true);
    const result = await generateHookScript(appName, aiConfig);
    setGeneratedResult(result || '');
    setIsGenerating(false);
  };

  const handlePushToGithub = async () => {
    if (!generatedResult) return;
    setIsPushing(true);
    try {
      await import('./services/aiService').then(m => m.pushToGithub(generatedResult, appName, aiConfig));
      alert("推送成功！GitHub Actions 已触发编译。");
    } catch (error: any) {
      alert(`推送失败: ${error.message}`);
    } finally {
      setIsPushing(false);
    }
  };

  const handleResearch = async () => {
    if (!aiConfig.apiKey) {
      alert("请先在设置中配置 API Key");
      setActiveTab('settings');
      return;
    }
    setIsGenerating(true);
    const result = await researchMethod(researchQuery, aiConfig);
    setResearchResult(result || '');
    setIsGenerating(false);
  };

  const copyToClipboard = async (text: string, type: 'builder' | 'researcher') => {
    if (!text) return;
    try {
      if (navigator.clipboard) {
        await navigator.clipboard.writeText(text);
      } else {
        const textArea = document.createElement("textarea");
        textArea.value = text;
        document.body.appendChild(textArea);
        textArea.select();
        document.execCommand('copy');
        document.body.removeChild(textArea);
      }
      setCopying(type);
      setTimeout(() => setCopying(null), 2000);
    } catch (err) {
      console.error('Failed to copy: ', err);
      alert('复制失败，请尝试手动选择复制');
    }
  };

  const platformIcons = {
    Theos: <Box className="w-4 h-4" />,
    QuantumultX: <Zap className="w-4 h-4" />,
    Surge: <Wind className="w-4 h-4" />,
    Loon: <Bird className="w-4 h-4" />
  };

  return (
    <div className="min-h-screen bg-[#E4E3E0] text-[#141414] font-sans selection:bg-[#141414] selection:text-[#E4E3E0]">
      {/* Sidebar Navigation */}
      <nav className="fixed left-0 top-0 h-full w-64 border-r border-[#141414] bg-[#E4E3E0] z-10 flex flex-col p-6">
        <div className="flex items-center gap-3 mb-12">
          <div className="w-10 h-10 bg-[#141414] rounded-sm flex items-center justify-center">
            <Cpu className="text-[#E4E3E0] w-6 h-6" />
          </div>
          <div>
            <h1 className="font-bold text-xl leading-none">iOS 插件</h1>
            <p className="text-[10px] font-mono opacity-50 uppercase tracking-widest mt-1">v1.2.0-稳定版</p>
          </div>
        </div>

        <div className="space-y-2 flex-grow">
          <NavButton 
            active={activeTab === 'builder'} 
            onClick={() => setActiveTab('builder')}
            icon={<Code2 className="w-4 h-4" />}
            label="DYLIB 源码生成"
          />
          <NavButton 
            active={activeTab === 'researcher'} 
            onClick={() => setActiveTab('researcher')}
            icon={<Search className="w-4 h-4" />}
            label="类方法库搜索"
          />
          <NavButton 
            active={activeTab === 'guides'} 
            onClick={() => setActiveTab('guides')}
            icon={<BookOpen className="w-4 h-4" />}
            label="Dylib 注入指南"
          />
          <NavButton 
            active={activeTab === 'settings'} 
            onClick={() => setActiveTab('settings')}
            icon={<Settings className="w-4 h-4" />}
            label="API 接口配置"
          />
        </div>

        <div className="mt-auto space-y-4">
          <div className="flex items-center gap-3 p-3 bg-white/50 border border-[#141414]/10 rounded-sm">
            <div className="w-8 h-8 rounded-full bg-[#141414] flex items-center justify-center overflow-hidden">
               {user?.photoURL ? <img src={user.photoURL} alt="Avatar" className="w-full h-full object-cover" /> : <UserIcon className="text-white w-4 h-4" />}
            </div>
            <div className="overflow-hidden">
              <p className="text-[10px] font-bold truncate">{user?.displayName || '管理员'}</p>
              <p className="text-[8px] font-mono opacity-50 truncate">{user?.email}</p>
            </div>
            <button 
              onClick={logout}
              title="登出系统"
              className="ml-auto p-1 text-red-500 hover:bg-neutral-200 rounded-sm transition-colors"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>

          <div className="bg-[#141414] text-[#E4E3E0] p-4 rounded-sm">
            <p className="text-[10px] font-mono opacity-60 mb-2">系统状态</p>
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
              <span className="text-xs font-mono uppercase">已认证/运行中</span>
            </div>
          </div>
        </div>
      </nav>

      {/* Main Content Area */}
      <main className="pl-64 min-h-screen">
        <AnimatePresence mode="wait">
          {activeTab === 'builder' && (
            <motion.div 
              key="builder"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              className="p-12 max-w-5xl"
            >
              <header className="mb-12 border-b border-[#141414] pb-6">
                <span className="text-[11px] font-serif italic opacity-50 uppercase tracking-wider mb-2 block">模块 01</span>
                <h2 className="text-6xl font-bold tracking-tighter">源码生成器</h2>
                <p className="mt-4 text-lg opacity-70 max-w-2xl font-serif italic">
                  基于 Logos (.xm) 语法，生成用于制作 Dylib 插件的 Hook 源码，强制绕过应用层广告。
                </p>
              </header>

              <div className="grid grid-cols-12 gap-8">
                <div className="col-span-12 lg:col-span-5 space-y-8">
                  <section className="space-y-4">
                    <label className="text-[11px] font-mono opacity-50 uppercase tracking-widest block">目标对象</label>
                    <div className="relative group">
                      <input 
                        type="text" 
                        value={appName}
                        onChange={(e) => setAppName(e.target.value)}
                        placeholder="例如: 河马剧场"
                        className="w-full bg-transparent border-b-2 border-[#141414] py-3 px-1 text-2xl font-bold focus:outline-none focus:border-opacity-50 transition-all"
                      />
                      <Smartphone className="absolute right-2 top-4 w-5 h-5 opacity-20 group-focus-within:opacity-50 transition-opacity" />
                    </div>
                  </section>

                  <section className="space-y-4 font-mono">
                    <label className="text-[11px] opacity-50 uppercase tracking-widest block">快捷对象预设</label>
                    <div className="flex flex-wrap gap-2">
                      {['河马剧场', '番茄小说', '抖音', 'B站', '小红书'].map(name => (
                        <button 
                          key={name}
                          onClick={() => setAppName(name)}
                          className={cn(
                            "px-3 py-1 border border-[#141414] text-[10px] transition-colors",
                            appName === name ? "bg-[#141414] text-[#E4E3E0]" : "hover:bg-[#141414] hover:text-[#E4E3E0]"
                          )}
                        >
                          {name}
                        </button>
                      ))}
                    </div>
                  </section>

                  <div className="p-4 bg-amber-50 border border-amber-200 rounded-sm">
                    <p className="text-[10px] font-mono leading-tight opacity-70">
                      INFO: 生成的代码需要使用 Theos 进行编译。
                      <br />编译目标：iPhoneOS ARM64
                    </p>
                  </div>

                  <button 
                    onClick={handleGenerate}
                    disabled={isGenerating}
                    className="w-full h-16 bg-[#141414] text-[#E4E3E0] font-bold text-lg flex items-center justify-center gap-3 hover:translate-y-[-2px] hover:shadow-[0_4px_0_0_#000] active:translate-y-[0] transition-all disabled:opacity-50"
                  >
                    {isGenerating ? (
                      <>
                        <RotateCcw className="w-5 h-5 animate-spin" />
                        正在分析 SDK 符号...
                      </>
                    ) : (
                      <>
                        <Zap className="w-5 h-5" />
                        生成 LOGOS 源码
                      </>
                    )}
                  </button>
                </div>

                <div className="col-span-12 lg:col-span-7">
                  <label className="text-[11px] font-mono opacity-50 uppercase tracking-widest block mb-4">LOGOS (.XM) 源代码</label>
                  <div className="relative group overflow-hidden border border-[#141414] rounded-sm bg-[#141414]">
                    <div className="absolute right-4 top-4 flex gap-2 z-10">
                      {generatedResult && (
                        <button 
                          onClick={handlePushToGithub}
                          disabled={isPushing}
                          title="推送到 GitHub 并自动编译"
                          className="flex items-center gap-2 px-3 py-2 bg-blue-600 hover:bg-blue-700 text-white transition-colors rounded-sm text-xs font-bold disabled:opacity-50"
                        >
                          {isPushing ? <RotateCcw className="w-3 h-3 animate-spin" /> : <Download className="w-3 h-3" />}
                          {isPushing ? '正在推送...' : '一键云编译'}
                        </button>
                      )}
                      <button 
                        onClick={() => copyToClipboard(generatedResult, 'builder')}
                        className="p-2 bg-[#E4E3E0]/10 hover:bg-[#E4E3E0]/20 text-[#E4E3E0] transition-colors rounded-sm"
                      >
                        {copying === 'builder' ? <Check className="w-4 h-4" /> : <Copy className="w-4 h-4" />}
                      </button>
                    </div>
                    <div className="h-[500px] overflow-auto p-6 font-mono text-xs leading-relaxed text-[#E4E3E0]">
                      <ReactMarkdown rehypePlugins={[rehypeHighlight]}>
                        {generatedResult ? `\`\`\`objectivec\n${generatedResult}\n\`\`\`` : `// 等待生成指令...
// 目标对象: ${appName}`}
                      </ReactMarkdown>
                    </div>
                  </div>
                </div>
              </div>
            </motion.div>
          )}

          {activeTab === 'researcher' && (
            <motion.div 
              key="researcher"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              className="p-12 max-w-5xl"
            >
              <header className="mb-12 border-b border-[#141414] pb-6">
                <span className="text-[11px] font-serif italic opacity-50 uppercase tracking-wider mb-2 block">模块 02</span>
                <h2 className="text-6xl font-bold tracking-tighter">符号研究员</h2>
                <p className="mt-4 text-lg opacity-70 max-w-2xl font-serif italic">
                  反编译常见的广告 SDK（如 BUAdSDK、GDTMobSDK）的类名和方法名，精准定位 Hook 点。
                </p>
              </header>

              <div className="space-y-8">
                <div className="flex gap-4">
                  <div className="relative flex-grow">
                    <input 
                      type="text" 
                      value={researchQuery}
                      onChange={(e) => setResearchQuery(e.target.value)}
                      placeholder="搜索类名 (例如: BUNativeAd, GDTMobAdView)..."
                      className="w-full bg-transparent border-2 border-[#141414] h-16 pl-14 pr-4 font-mono focus:outline-none focus:bg-[#141414]/5 transition-all"
                    />
                    <Search className="absolute left-5 top-5 w-6 h-6 opacity-30" />
                  </div>
                  <button 
                    onClick={handleResearch}
                    disabled={isGenerating}
                    className="px-12 bg-[#141414] text-[#E4E3E0] font-bold hover:opacity-90 transition-all"
                  >
                    开始研究
                  </button>
                </div>

                <div className="bg-white/50 border border-[#141414] rounded-sm min-h-[400px] relative overflow-hidden group">
                  <div className="absolute right-4 top-4 opacity-0 group-hover:opacity-100 transition-opacity z-10">
                    <button 
                      onClick={() => copyToClipboard(researchResult, 'researcher')}
                      className="p-2 bg-[#141414]/5 hover:bg-[#141414]/10 transition-colors border border-[#141414]/20 rounded-sm"
                    >
                      {copying === 'researcher' ? <Check className="w-4 h-4" /> : <Copy className="w-4 h-4 text-[#141414]" />}
                    </button>
                  </div>
                  
                  <div className="p-8 h-[500px] overflow-auto font-mono text-sm leading-relaxed">
                    {isGenerating ? (
                       <div className="flex flex-col items-center justify-center p-20 opacity-30 h-full">
                          <RotateCcw className="w-12 h-12 animate-spin mb-4" />
                          <p className="animate-pulse">正在解析符号表...</p>
                       </div>
                    ) : researchResult ? (
                      <div className="markdown-body">
                        <ReactMarkdown rehypePlugins={[rehypeHighlight]}>
                          {researchResult}
                        </ReactMarkdown>
                      </div>
                    ) : (
                      <div className="flex flex-col items-center justify-center p-20 opacity-20 h-full">
                        <Terminal className="w-16 h-16 mb-4" />
                        <p>输入类名或方法名开始分析</p>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </motion.div>
          )}

          {activeTab === 'guides' && (
            <motion.div 
              key="guides"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              className="p-12 max-w-5xl"
            >
              <header className="mb-12 border-b border-[#141414] pb-6">
                <span className="text-[11px] font-serif italic opacity-50 uppercase tracking-wider mb-2 block">模块 03</span>
                <h2 className="text-6xl font-bold tracking-tighter">注入指南</h2>
              </header>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-12">
                <section className="space-y-6">
                  <h3 className="text-2xl font-bold flex items-center gap-3">
                    <Smartphone className="w-6 h-6" />
                    第一步：解密与获取
                  </h3>
                  <div className="space-y-4 font-serif italic text-lg leading-relaxed">
                    <p className="flex gap-4">
                      <span className="font-mono text-sm not-italic opacity-40">01.</span>
                      使用 <b>DumpDecrypter</b> 或 <b>Frida-ios-dump</b> 从越狱手机上砸壳获取未加密的 IPA 文件。
                    </p>
                    <p className="flex gap-4">
                      <span className="font-mono text-sm not-italic opacity-40">02.</span>
                      使用解压工具查看 Payload 中的二进制主程序文件名。
                    </p>
                  </div>
                </section>

                <section className="space-y-6">
                  <h3 className="text-2xl font-bold flex items-center gap-3">
                    <Box className="w-6 h-6" />
                    第二步：开发与编译
                  </h3>
                  <div className="space-y-4 font-serif italic text-lg leading-relaxed">
                    <p className="flex gap-4">
                      <span className="font-mono text-sm not-italic opacity-40">01.</span>
                      配置 <b>Theos</b> 开发环境，创建 <b>tweak</b> 模板。
                    </p>
                    <p className="flex gap-4">
                      <span className="font-mono text-sm not-italic opacity-40">02.</span>
                      将本站生成的 <b>.xm</b> 代码复制到项目文件夹。
                    </p>
                    <p className="flex gap-4">
                      <span className="font-mono text-sm not-italic opacity-40">03.</span>
                      执行 <code className="bg-[#141414]/10 not-italic px-1 font-mono text-sm">make package</code> 编译生成 .dylib 文件。
                    </p>
                  </div>
                </section>

                <section className="space-y-6">
                  <h3 className="text-2xl font-bold flex items-center gap-3">
                    <Layers className="w-6 h-6" />
                    第三步：注入与打包
                  </h3>
                  <div className="space-y-4 font-serif italic text-lg leading-relaxed">
                    <p className="flex gap-4">
                      <span className="font-mono text-sm not-italic opacity-40">01.</span>
                      使用 <b>optool</b> 或 <b>yololib</b> 将生成的 dylib 路径添加至 Mach-O 的 Load Commands 中。
                    </p>
                    <p className="flex gap-4">
                      <span className="font-mono text-sm not-italic opacity-40">02.</span>
                      确保将生成的 dylib 文件一同放入 App 目录中。
                    </p>
                    <p className="flex gap-4">
                      <span className="font-mono text-sm not-italic opacity-40">03.</span>
                      如果有依赖项（如 CydiaSubstrate），需一并打包并修改 Dylib ID。
                    </p>
                  </div>
                </section>

                <section className="space-y-6">
                  <h3 className="text-2xl font-bold flex items-center gap-3">
                    <Zap className="w-6 h-6" />
                    第四步：侧载与测试
                  </h3>
                  <div className="space-y-4 font-serif italic text-lg leading-relaxed">
                    <p className="flex gap-4">
                      <span className="font-mono text-sm not-italic opacity-40">01.</span>
                      使用 <b>Sideloadly</b>、<b>AltStore</b> 或 <b>爱思助手</b> 重新签名并安装 IPA。
                    </p>
                    <p className="flex gap-4">
                      <span className="font-mono text-sm not-italic opacity-40">02.</span>
                      打开应用，验证 Hook 是否生效。
                    </p>
                  </div>
                </section>

                <section className="col-span-1 md:col-span-2 p-8 bg-[#141414] text-[#E4E3E0] rounded-sm">
                  <div className="flex items-center gap-4 mb-6">
                    <Settings className="w-8 h-8 text-blue-400" />
                    <h3 className="text-2xl font-bold uppercase tracking-tight">GitHub Actions 自动化编译 (CI/CD)</h3>
                  </div>
                  <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                    <div className="space-y-4 font-serif italic text-sm leading-relaxed">
                      <p>
                        借用 GitHub 的云端服务器进行编译。在仓库创建 <code className="bg-white/10 px-1">.github/workflows/build.yml</code> 即可。
                      </p>
                      <ul className="list-disc pl-6 space-y-2 text-xs not-italic font-sans opacity-80">
                        <li><b>无需本地 Mac：</b>GitHub 虚拟环境自带 macOS，可直接安装 Theos。</li>
                        <li><b>自动交付：</b>编译成功后自动发布 Release 包供下载。</li>
                      </ul>
                    </div>
                    <div className="bg-white/5 p-4 rounded font-mono text-[9px] leading-tight overflow-x-auto whitespace-pre">
{`# 简易 build.yml 示例
jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Theos
        run: |
          git clone --recursive https://github.com/theos/theos.git ~/theos
      - name: Make
        run: make package`}
                    </div>
                  </div>
                </section>
              </div>

              <div className="mt-16 p-8 border border-[#141414] bg-[#141414]/5 rounded-sm space-y-4">
                <div className="flex items-center gap-4 text-[#141414]">
                  <ShieldAlert className="w-8 h-8" />
                  <h4 className="text-xl font-bold uppercase tracking-tight">使用与本地化 FAQ</h4>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-8 text-xs font-mono leading-relaxed">
                  <div>
                    <p className="font-bold border-b border-[#141414]/20 pb-1 mb-2 text-blue-600">Q: 生成的代码在什么位置？如何编译？</p>
                    <div className="opacity-70 space-y-2">
                      <p>1. <b>位置：</b> 点击生成后，代码会显示在右侧框中。点击复制图标即可获取全部 <code className="bg-black/5 px-1">Tweak.xm</code> 源码。</p>
                      <p>2. <b>GitHub 编译：</b> 导出项目并上传至 GitHub 后，将复制的代码保存为仓库根目录下的 <code className="bg-black/5 px-1">Tweak.xm</code>。项目已包含 <code className="bg-black/5 px-1">Makefile</code> 和 <code className="bg-black/5 px-1">control</code>，Push 后 Actions 会自动开始编译。</p>
                      <p>3. <b>下载 DEB：</b> 编译完成后，在 GitHub Actions 任务详情页的 <b>Artifacts</b> 处下载编译好的 DEB 插件。</p>
                    </div>
                  </div>
                  <div>
                    <p className="font-bold border-b border-[#141414]/20 pb-1 mb-2 text-blue-600">Q: 如何使用宝塔部署？</p>
                    <p className="opacity-70">
                      1. 在宝塔 docker 页面中点击 <b>添加项目</b>。<br />
                      2. 选择项目目录，宝塔会自动识别 <code className="bg-black/5 px-1">docker-compose.yml</code>。<br />
                      3. 在 <b>环境变量</b> 处点击“添加”，输入 <code className="bg-black/5 px-1">GEMINI_API_KEY</code> 或 <code className="bg-black/5 px-1">OPENAI_API_KEY</code>。<br />
                      4. 点击确认启动，访问地址为：<code className="bg-black/5 px-1">http://服务器IP:12300</code>。
                    </p>
                  </div>
                </div>
                <p className="text-[10px] opacity-40 pt-4 border-t border-[#141414]/10">
                  声明：生成的代码仅供研究。生成的 Dylib 开发需要一定的 Mach-O 处理基础。
                </p>
              </div>
            </motion.div>
          )}
          {activeTab === 'settings' && (
            <motion.div 
              key="settings"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              className="p-12 max-w-4xl"
            >
              <header className="mb-12 border-b border-[#141414] pb-6">
                <span className="text-[11px] font-serif italic opacity-50 uppercase tracking-wider mb-2 block">系统配置</span>
                <h2 className="text-6xl font-bold tracking-tighter">API 接口设置</h2>
                <p className="mt-4 text-lg opacity-70 font-serif italic">
                  配置 AI 生成引擎。支持 Google Gemini 以及任意兼容 OpenAI 协议的接口（如 DeepSeek, GPT-4）。
                </p>
              </header>

              <div className="space-y-8 bg-white p-8 border border-[#141414] rounded-sm">
                <div className="grid grid-cols-2 gap-8">
                  <section className="space-y-4">
                    <label className="text-[11px] font-mono opacity-50 uppercase tracking-widest block">AI 服务商</label>
                    <select 
                      value={aiConfig.provider}
                      onChange={(e) => setAiConfig({...aiConfig, provider: e.target.value as any})}
                      className="w-full bg-transparent border-2 border-[#141414] h-12 px-4 font-mono focus:outline-none"
                    >
                      <option value="gemini">Google Gemini</option>
                      <option value="openai">OpenAI 兼容 (OpenAI/DeepSeek/Claude)</option>
                    </select>
                  </section>
                  <section className="space-y-4">
                    <label className="text-[11px] font-mono opacity-50 uppercase tracking-widest block">模型名称 (Model Name)</label>
                    <input 
                      type="text" 
                      value={aiConfig.modelName}
                      onChange={(e) => setAiConfig({...aiConfig, modelName: e.target.value})}
                      placeholder={aiConfig.provider === 'gemini' ? 'gemini-1.5-flash' : 'gpt-4 / deepseek-chat'}
                      className="w-full bg-transparent border-2 border-[#141414] h-12 px-4 font-mono focus:outline-none"
                    />
                  </section>
                </div>

                <section className="space-y-4">
                  <label className="text-[11px] font-mono opacity-50 uppercase tracking-widest block">API KEY</label>
                  <input 
                    type="password" 
                    value={aiConfig.apiKey}
                    onChange={(e) => setAiConfig({...aiConfig, apiKey: e.target.value})}
                    placeholder="输入您的 API 密钥"
                    className="w-full bg-transparent border-2 border-[#141414] h-12 px-4 font-mono focus:outline-none"
                  />
                </section>

                {aiConfig.provider === 'openai' && (
                  <section className="space-y-4">
                    <label className="text-[11px] font-mono opacity-50 uppercase tracking-widest block">接口地址 (Base URL)</label>
                    <input 
                      type="text" 
                      value={aiConfig.baseUrl}
                      onChange={(e) => setAiConfig({...aiConfig, baseUrl: e.target.value})}
                      placeholder="https://api.openai.com/v1"
                      className="w-full bg-transparent border-2 border-[#141414] h-12 px-4 font-mono focus:outline-none"
                    />
                    <p className="text-[10px] opacity-40 italic">支持 DeepSeek: https://api.deepseek.com</p>
                  </section>
                )}

                <div className="pt-8 mt-8 border-t-2 border-[#141414] space-y-8">
                  <h3 className="text-xl font-bold flex items-center gap-2">
                    <Download className="w-5 h-5" />
                    GitHub 自动化配置
                  </h3>
                  
                  <div className="grid grid-cols-2 gap-8">
                    <section className="space-y-4">
                      <label className="text-[11px] font-mono opacity-50 uppercase tracking-widest block underline decoration-blue-500 decoration-2">GitHub Token (必填)</label>
                      <input 
                        type="password" 
                        value={aiConfig.githubToken || ''}
                        onChange={(e) => setAiConfig({...aiConfig, githubToken: e.target.value})}
                        placeholder="ghp_xxxxxxxxxxxx"
                        className="w-full bg-transparent border-2 border-[#141414] h-12 px-4 font-mono focus:outline-none"
                      />
                      <p className="text-[9px] opacity-80 text-orange-400 font-bold">！重要：生成 Token 时必须勾选 'workflow' 权限，否则无法更新编译脚本。</p>
                      <p className="text-[9px] opacity-50">需要 repo 权限。用于将代码推送到您的仓库。</p>
                    </section>
                    <section className="space-y-4">
                      <label className="text-[11px] font-mono opacity-50 uppercase tracking-widest block">仓库路径 (Owner/Repo)</label>
                      <input 
                        type="text" 
                        value={aiConfig.githubRepo || ''}
                        onChange={(e) => setAiConfig({...aiConfig, githubRepo: e.target.value})}
                        placeholder="shine85/ios--Tweak"
                        className="w-full bg-transparent border-2 border-[#141414] h-12 px-4 font-mono focus:outline-none"
                      />
                    </section>
                  </div>
                </div>

                <div className="pt-6 border-t border-[#141414]/10">
                   <p className="text-xs opacity-50 mb-4 font-serif">配置将保存在当前会话。生产环境下建议通过 Docker 环境变量或 .env 文件预设。</p>
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </main>
    </div>
  );
}

function NavButton({ active, onClick, icon, label }: { active: boolean, onClick: () => void, icon: React.ReactNode, label: string }) {
  return (
    <button 
      onClick={onClick}
      className={cn(
        "w-full flex items-center gap-3 px-4 py-3 text-[11px] font-mono tracking-widest transition-all rounded-sm",
        active 
          ? "bg-[#141414] text-[#E4E3E0] translate-x-2" 
          : "hover:bg-[#141414]/5 opacity-60 hover:opacity-100"
      )}
    >
      {icon}
      {label}
    </button>
  );
}

