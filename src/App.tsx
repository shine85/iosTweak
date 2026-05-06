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
  Upload,
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
import { useI18n } from './components/I18nProvider';

type Tab = 'builder' | 'researcher' | 'guides' | 'settings';

export default function App() {
  const { t, locale, setLocale } = useI18n();
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState<Tab>('builder');
  const [appName, setAppName] = useState('Hippo Cinema');
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
      alert(t('builder.noApiKey'));
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
      alert(t('builder.pushSuccess'));
    } catch (error: any) {
      alert(`${t('builder.pushFailed')}${error.message}`);
    } finally {
      setIsPushing(false);
    }
  };

  const handleResearch = async () => {
    if (!aiConfig.apiKey) {
      alert(t('builder.noApiKey'));
      setActiveTab('settings');
      return;
    }
    setIsGenerating(true);
    const result = await researchMethod(researchQuery, aiConfig);
    setResearchResult(result || '');
    setIsGenerating(false);
  };

  const handleExportConfig = () => {
    const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(aiConfig, null, 2));
    const downloadAnchorNode = document.createElement('a');
    downloadAnchorNode.setAttribute("href",     dataStr);
    downloadAnchorNode.setAttribute("download", "ios_tweak_config.json");
    document.body.appendChild(downloadAnchorNode);
    downloadAnchorNode.click();
    downloadAnchorNode.remove();
  };

  const handleImportConfig = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const str = e.target?.result as string;
        const newConfig = JSON.parse(str);
        if (newConfig && typeof newConfig === 'object') {
          setAiConfig(prev => ({ ...prev, ...newConfig }));
          alert('配置导入成功 / Configuration imported successfully');
        }
      } catch (err) {
        alert('配置解析失败，请检查文件格式 / Failed to parse configuration file');
      }
    };
    reader.readAsText(file);
    // Reset input
    event.target.value = '';
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
      alert(t('builder.copyFailed'));
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
            <h1 className="font-bold text-xl leading-none">{t('common.appName')}</h1>
            <p className="text-[10px] font-mono opacity-50 uppercase tracking-widest mt-1">{t('common.version')}</p>
          </div>
        </div>

        <div className="space-y-2 flex-grow">
          <NavButton 
            active={activeTab === 'builder'} 
            onClick={() => setActiveTab('builder')}
            icon={<Code2 className="w-4 h-4" />}
            label={t('nav.builder')}
          />
          <NavButton 
            active={activeTab === 'researcher'} 
            onClick={() => setActiveTab('researcher')}
            icon={<Search className="w-4 h-4" />}
            label={t('nav.researcher')}
          />
          <NavButton 
            active={activeTab === 'guides'} 
            onClick={() => setActiveTab('guides')}
            icon={<BookOpen className="w-4 h-4" />}
            label={t('nav.guides')}
          />
          <NavButton 
            active={activeTab === 'settings'} 
            onClick={() => setActiveTab('settings')}
            icon={<Settings className="w-4 h-4" />}
            label={t('nav.settings')}
          />
        </div>

        <div className="mt-auto space-y-4">
          <div className="flex items-center gap-3 p-3 bg-white/50 border border-[#141414]/10 rounded-sm">
            <div className="w-8 h-8 rounded-full bg-[#141414] flex items-center justify-center overflow-hidden">
               {user?.photoURL ? <img src={user.photoURL} alt="Avatar" className="w-full h-full object-cover" /> : <UserIcon className="text-white w-4 h-4" />}
            </div>
            <div className="overflow-hidden">
              <p className="text-[10px] font-bold truncate">{user?.displayName || t('common.admin')}</p>
              <p className="text-[8px] font-mono opacity-50 truncate">{user?.email}</p>
            </div>
            <button 
              onClick={logout}
              title={t('common.logout')}
              className="ml-auto p-1 text-red-500 hover:bg-neutral-200 rounded-sm transition-colors"
            >
              <LogOut className="w-4 h-4" />
            </button>
          </div>

          <div className="bg-[#141414] text-[#E4E3E0] p-4 rounded-sm">
            <p className="text-[10px] font-mono opacity-60 mb-2">{t('common.status')}</p>
            <div className="flex items-center gap-2">
              <div className="w-2 h-2 bg-green-500 rounded-full animate-pulse" />
              <span className="text-xs font-mono uppercase">{t('common.running')}</span>
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
                <span className="text-[11px] font-serif italic opacity-50 uppercase tracking-wider mb-2 block">{t('builder.module')}</span>
                <h2 className="text-6xl font-bold tracking-tighter">{t('builder.title')}</h2>
                <p className="mt-4 text-lg opacity-70 max-w-2xl font-serif italic">
                  {t('builder.subtitle')}
                </p>
              </header>

              <div className="grid grid-cols-12 gap-8">
                <div className="col-span-12 lg:col-span-5 space-y-8">
                  <section className="space-y-4">
                    <label className="text-[11px] font-mono opacity-50 uppercase tracking-widest block">{t('builder.target')}</label>
                    <div className="relative group">
                      <input 
                        type="text" 
                        value={appName}
                        onChange={(e) => setAppName(e.target.value)}
                        placeholder={t('builder.placeholder')}
                        className="w-full bg-transparent border-b-2 border-[#141414] py-3 px-1 text-2xl font-bold focus:outline-none focus:border-opacity-50 transition-all"
                      />
                      <Smartphone className="absolute right-2 top-4 w-5 h-5 opacity-20 group-focus-within:opacity-50 transition-opacity" />
                    </div>
                  </section>

                  <section className="space-y-4 font-mono">
                    <label className="text-[11px] opacity-50 uppercase tracking-widest block">{t('builder.presets')}</label>
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
                    <p className="text-[10px] font-mono leading-tight opacity-70 whitespace-pre-wrap">
                      {t('builder.infoText')}
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
                        {t('builder.generating')}
                      </>
                    ) : (
                      <>
                        <Zap className="w-5 h-5" />
                        {t('builder.generate')}
                      </>
                    )}
                  </button>
                </div>

                <div className="col-span-12 lg:col-span-7">
                  <label className="text-[11px] font-mono opacity-50 uppercase tracking-widest block mb-4">{t('builder.sourceCode')}</label>
                  <div className="relative group overflow-hidden border border-[#141414] rounded-sm bg-[#141414]">
                    <div className="absolute right-4 top-4 flex gap-2 z-10">
                      {generatedResult && (
                        <button 
                          onClick={handlePushToGithub}
                          disabled={isPushing}
                          title={t('builder.pushGithub')}
                          className="flex items-center gap-2 px-3 py-2 bg-blue-600 hover:bg-blue-700 text-white transition-colors rounded-sm text-xs font-bold disabled:opacity-50"
                        >
                          {isPushing ? <RotateCcw className="w-3 h-3 animate-spin" /> : <Download className="w-3 h-3" />}
                          {isPushing ? t('builder.pushing') : t('builder.pushGithub')}
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
                        {generatedResult ? `\`\`\`objectivec\n${generatedResult}\n\`\`\`` : t('builder.waitInstructions', { appName })}
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
                <span className="text-[11px] font-serif italic opacity-50 uppercase tracking-wider mb-2 block">{t('researcher.module')}</span>
                <h2 className="text-6xl font-bold tracking-tighter">{t('researcher.title')}</h2>
                <p className="mt-4 text-lg opacity-70 max-w-2xl font-serif italic">
                  {t('researcher.subtitle')}
                </p>
              </header>

              <div className="space-y-8">
                <div className="flex gap-4">
                  <div className="relative flex-grow">
                    <input 
                      type="text" 
                      value={researchQuery}
                      onChange={(e) => setResearchQuery(e.target.value)}
                      placeholder={t('researcher.placeholder')}
                      className="w-full bg-transparent border-2 border-[#141414] h-16 pl-14 pr-4 font-mono focus:outline-none focus:bg-[#141414]/5 transition-all"
                    />
                    <Search className="absolute left-5 top-5 w-6 h-6 opacity-30" />
                  </div>
                  <button 
                    onClick={handleResearch}
                    disabled={isGenerating}
                    className="px-12 bg-[#141414] text-[#E4E3E0] font-bold hover:opacity-90 transition-all flex items-center justify-center gap-2"
                  >
                    {isGenerating && <RotateCcw className="w-4 h-4 animate-spin" />}
                    {t('researcher.button')}
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
                          <p className="animate-pulse">{t('researcher.analyzing')}</p>
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
                        <p>{t('researcher.emptyState')}</p>
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
                <span className="text-[11px] font-serif italic opacity-50 uppercase tracking-wider mb-2 block">{t('guides.module')}</span>
                <h2 className="text-6xl font-bold tracking-tighter">{t('guides.title')}</h2>
              </header>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-12">
                <section className="space-y-6">
                  <h3 className="text-2xl font-bold flex items-center gap-3">
                    <Smartphone className="w-6 h-6" />
                    {t('guides.step1.title')}
                  </h3>
                  <div className="space-y-4 font-serif italic text-lg leading-relaxed">
                    <p className="flex gap-4">
                      <span className="font-mono text-sm not-italic opacity-40">01.</span>
                      {t('guides.step1.p1')}
                    </p>
                    <p className="flex gap-4">
                      <span className="font-mono text-sm not-italic opacity-40">02.</span>
                      {t('guides.step1.p2')}
                    </p>
                  </div>
                </section>

                <section className="space-y-6">
                  <h3 className="text-2xl font-bold flex items-center gap-3">
                    <Box className="w-6 h-6" />
                    {t('guides.step2.title')}
                  </h3>
                  <div className="space-y-4 font-serif italic text-lg leading-relaxed">
                    <p className="flex gap-4">
                      <span className="font-mono text-sm not-italic opacity-40">01.</span>
                      {t('guides.step2.p1')}
                    </p>
                    <p className="flex gap-4">
                      <span className="font-mono text-sm not-italic opacity-40">02.</span>
                      {t('guides.step2.p2')}
                    </p>
                    <p className="flex gap-4">
                      <span className="font-mono text-sm not-italic opacity-40">03.</span>
                      {t('guides.step2.p3')}
                    </p>
                  </div>
                </section>

                <section className="space-y-6">
                  <h3 className="text-2xl font-bold flex items-center gap-3">
                    <Layers className="w-6 h-6" />
                    {t('guides.step3.title')}
                  </h3>
                  <div className="space-y-4 font-serif italic text-lg leading-relaxed">
                    <p className="flex gap-4">
                      <span className="font-mono text-sm not-italic opacity-40">01.</span>
                      {t('guides.step3.p1')}
                    </p>
                    <p className="flex gap-4">
                      <span className="font-mono text-sm not-italic opacity-40">02.</span>
                      {t('guides.step3.p2')}
                    </p>
                    <p className="flex gap-4">
                      <span className="font-mono text-sm not-italic opacity-40">03.</span>
                      {t('guides.step3.p3')}
                    </p>
                  </div>
                </section>

                <section className="space-y-6">
                  <h3 className="text-2xl font-bold flex items-center gap-3">
                    <Zap className="w-6 h-6" />
                    {t('guides.step4.title')}
                  </h3>
                  <div className="space-y-4 font-serif italic text-lg leading-relaxed">
                    <p className="flex gap-4">
                      <span className="font-mono text-sm not-italic opacity-40">01.</span>
                      {t('guides.step4.p1')}
                    </p>
                    <p className="flex gap-4">
                      <span className="font-mono text-sm not-italic opacity-40">02.</span>
                      {t('guides.step4.p2')}
                    </p>
                  </div>
                </section>

                <section className="col-span-1 md:col-span-2 p-8 bg-[#141414] text-[#E4E3E0] rounded-sm">
                  <div className="flex items-center gap-4 mb-6">
                    <Settings className="w-8 h-8 text-blue-400" />
                    <h3 className="text-2xl font-bold uppercase tracking-tight">{t('guides.githubActions.title')}</h3>
                  </div>
                  <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
                    <div className="space-y-4 font-serif italic text-sm leading-relaxed">
                      <p>
                        {t('guides.githubActions.p1')}
                      </p>
                      <ul className="list-disc pl-6 space-y-2 text-xs not-italic font-sans opacity-80">
                        <li><b>{t('guides.githubActions.noMac')}</b>{t('guides.githubActions.noMacDesc')}</li>
                        <li><b>{t('guides.githubActions.delivery')}</b>{t('guides.githubActions.deliveryDesc')}</li>
                      </ul>
                    </div>
                    <div className="bg-white/5 p-4 rounded font-mono text-[9px] leading-tight overflow-x-auto whitespace-pre">
{`${t('guides.githubActions.example')}
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
                  <h4 className="text-xl font-bold uppercase tracking-tight">{t('guides.faq.title')}</h4>
                </div>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-8 text-xs font-mono leading-relaxed">
                  <div>
                    <p className="font-bold border-b border-[#141414]/20 pb-1 mb-2 text-blue-600">{t('guides.faq.q1')}</p>
                    <div className="opacity-70 space-y-2">
                       <p>{t('guides.faq.q1a1')}</p>
                       <p>{t('guides.faq.q1a2')}</p>
                       <p>{t('guides.faq.q1a3')}</p>
                    </div>
                  </div>
                  <div>
                    <p className="font-bold border-b border-[#141414]/20 pb-1 mb-2 text-blue-600">{t('guides.faq.q2')}</p>
                    <p className="opacity-70">
                      {t('guides.faq.q2a1')}<br />
                      {t('guides.faq.q2a2')}<br />
                      {t('guides.faq.q2a3')}<br />
                      {t('guides.faq.q2a4')}
                    </p>
                  </div>
                </div>
                <p className="text-[10px] opacity-40 pt-4 border-t border-[#141414]/10">
                  {t('guides.disclaimer')}
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
                <span className="text-[11px] font-serif italic opacity-50 uppercase tracking-wider mb-2 block">{t('settings.module')}</span>
                <h2 className="text-6xl font-bold tracking-tighter">{t('settings.title')}</h2>
                <p className="mt-4 text-lg opacity-70 font-serif italic">
                  {t('settings.subtitle')}
                </p>
              </header>

              <div className="space-y-8 bg-white p-8 border border-[#141414] rounded-sm">
                <div className="grid grid-cols-2 gap-8">
                  <section className="space-y-4">
                    <label className="text-[11px] font-mono opacity-50 uppercase tracking-widest block">{t('settings.provider')}</label>
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
                    <label className="text-[11px] font-mono opacity-50 uppercase tracking-widest block">{t('settings.modelName')}</label>
                    <input 
                      type="text" 
                      value={aiConfig.modelName}
                      onChange={(e) => setAiConfig({...aiConfig, modelName: e.target.value})}
                      placeholder={aiConfig.provider === 'gemini' ? 'gemini-1.5-flash' : 'gpt-4 / deepseek-chat'}
                      className="w-full bg-transparent border-2 border-[#141414] h-12 px-4 font-mono focus:outline-none"
                    />
                  </section>
                </div>

                <div className="grid grid-cols-2 gap-8">
                  <section className="space-y-4">
                    <label className="text-[11px] font-mono opacity-50 uppercase tracking-widest block">{t('settings.apiKey')}</label>
                    <input 
                      type="password" 
                      value={aiConfig.apiKey}
                      onChange={(e) => setAiConfig({...aiConfig, apiKey: e.target.value})}
                      placeholder={t('settings.apiKeyPlaceholder')}
                      className="w-full bg-transparent border-2 border-[#141414] h-12 px-4 font-mono focus:outline-none"
                    />
                  </section>
                  <section className="space-y-4">
                    <label className="text-[11px] font-mono opacity-50 uppercase tracking-widest block">{t('settings.language')}</label>
                    <select 
                      value={locale}
                      onChange={(e) => setLocale(e.target.value as any)}
                      className="w-full bg-transparent border-2 border-[#141414] h-12 px-4 font-mono focus:outline-none"
                    >
                      <option value="zh">简体中文 (Chinese)</option>
                      <option value="en">English</option>
                    </select>
                  </section>
                </div>

                {aiConfig.provider === 'openai' && (
                  <section className="space-y-4">
                    <label className="text-[11px] font-mono opacity-50 uppercase tracking-widest block">{t('settings.baseUrl')}</label>
                    <input 
                      type="text" 
                      value={aiConfig.baseUrl}
                      onChange={(e) => setAiConfig({...aiConfig, baseUrl: e.target.value})}
                      placeholder="https://api.openai.com/v1"
                      className="w-full bg-transparent border-2 border-[#141414] h-12 px-4 font-mono focus:outline-none"
                    />
                    <p className="text-[10px] opacity-40 italic">{t('settings.baseUrlTip')}</p>
                  </section>
                )}

                <div className="pt-8 mt-8 border-t-2 border-[#141414] space-y-8">
                  <h3 className="text-xl font-bold flex items-center gap-2">
                    <Download className="w-5 h-5" />
                    {t('settings.githubTitle')}
                  </h3>
                  
                  <div className="grid grid-cols-2 gap-8">
                    <section className="space-y-4">
                      <label className="text-[11px] font-mono opacity-50 uppercase tracking-widest block underline decoration-blue-500 decoration-2">{t('settings.githubToken')}</label>
                      <input 
                        type="password" 
                        value={aiConfig.githubToken || ''}
                        onChange={(e) => setAiConfig({...aiConfig, githubToken: e.target.value})}
                        placeholder={t('settings.githubTokenPlaceholder')}
                        className="w-full bg-transparent border-2 border-[#141414] h-12 px-4 font-mono focus:outline-none"
                      />
                      <p className="text-[9px] opacity-80 text-orange-400 font-bold">{t('settings.githubTokenWarning')}</p>
                      <p className="text-[9px] opacity-50">{t('settings.githubTokenDesc')}</p>
                    </section>
                    <section className="space-y-4">
                      <label className="text-[11px] font-mono opacity-50 uppercase tracking-widest block">{t('settings.githubRepo')}</label>
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

                <div className="pt-6 border-t border-[#141414]/10 flex justify-between items-center">
                   <p className="text-xs opacity-50 font-serif">{t('settings.saveTip')}</p>
                   <div className="flex gap-4">
                    <button onClick={handleExportConfig} className="text-xs px-4 py-2 border border-[#141414] hover:bg-[#141414] hover:text-[#E4E3E0] transition-colors rounded-sm flex items-center gap-2">
                      <Download className="w-4 h-4" /> 导出配置 (Export)
                    </button>
                    <label className="text-xs px-4 py-2 border border-[#141414] hover:bg-[#141414] hover:text-[#E4E3E0] transition-colors rounded-sm flex items-center gap-2 cursor-pointer">
                      <Upload className="w-4 h-4" /> 导入配置 (Import)
                      <input type="file" accept=".json" className="hidden" onChange={handleImportConfig} />
                    </label>
                  </div>
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
        "w-full flex items-center gap-3 px-4 py-3 text-[11px] font-mono tracking-widest transition-all rounded-sm relative group",
        active 
          ? "bg-[#141414] text-[#E4E3E0] translate-x-2 shadow-[4px_4px_0_0_rgba(0,0,0,0.1)]" 
          : "hover:bg-[#141414]/5 opacity-60 hover:opacity-100"
      )}
    >
      {icon}
      {label}
      {active && (
        <motion.div 
          layoutId="active-indicator"
          className="absolute right-0 top-0 bottom-0 w-1 bg-blue-500 shadow-[0_0_8px_rgba(59,130,246,0.5)]"
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: 0.2 }}
        />
      )}
    </button>
  );
}

