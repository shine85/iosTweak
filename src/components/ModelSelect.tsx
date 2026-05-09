import React, { useState, useRef, useEffect } from 'react';
import { ChevronDown, Search, Check, Layers, RotateCcw } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { cn } from '../lib/utils';

interface ModelSelectProps {
  value: string;
  onChange: (value: string) => void;
  models: string[];
  onFetch: () => Promise<void>;
  isFetching: boolean;
  placeholder?: string;
}

export function ModelSelect({ value, onChange, models, onFetch, isFetching, placeholder }: ModelSelectProps) {
  const [isOpen, setIsOpen] = useState(false);
  const [search, setSearch] = useState('');
  const containerRef = useRef<HTMLDivElement>(null);

  const filteredModels = models.length > 0 
    ? models.filter(m => m.toLowerCase().includes(search.toLowerCase()))
    : [];

  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (containerRef.current && !containerRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    };
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  return (
    <div className="relative w-full" ref={containerRef}>
      <div className="flex gap-2">
        <div 
          onClick={() => setIsOpen(!isOpen)}
          className="flex-grow bg-transparent border-2 border-[#141414] h-12 px-4 font-mono flex items-center cursor-pointer hover:bg-gray-50 transition-colors overflow-hidden"
        >
          <span className="truncate">{value || placeholder}</span>
        </div>
        <button
          onClick={() => setIsOpen(!isOpen)}
          className="w-12 h-12 border-2 border-[#141414] flex items-center justify-center hover:bg-[#FFE100] transition-colors"
        >
          <ChevronDown className={cn("w-5 h-5 transition-transform", isOpen && "rotate-180")} />
        </button>
      </div>

      <AnimatePresence>
        {isOpen && (
          <motion.div
            initial={{ opacity: 0, y: 10 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: 10 }}
            className="absolute left-0 right-0 mt-2 bg-white border-2 border-[#141414] shadow-[8px_8px_0px_0px_rgba(20,20,20,1)] z-[50] flex flex-col max-h-[400px]"
          >
            {/* Search & Fetch */}
            <div className="p-3 border-b-2 border-[#141414] space-y-3">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 opacity-40" />
                <input 
                  type="text"
                  placeholder="搜索或输入模型..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 bg-gray-50 border-2 border-[#141414] font-mono text-sm focus:outline-none focus:bg-white"
                  autoFocus
                />
              </div>
              <button
                onClick={(e) => {
                  e.stopPropagation();
                  onFetch();
                }}
                disabled={isFetching}
                className="w-full h-10 bg-[#141414] text-white font-mono text-[10px] uppercase tracking-widest flex items-center justify-center gap-2 hover:bg-[#333] transition-colors disabled:opacity-50"
              >
                {isFetching ? <RotateCcw className="w-3 h-3 animate-spin" /> : <Layers className="w-3 h-3" />}
                {isFetching ? "获取中..." : "获取最新模型列表"}
              </button>
            </div>

            {/* List */}
            <div className="overflow-y-auto custom-scrollbar flex-1">
              {filteredModels.length > 0 ? (
                filteredModels.map((model) => (
                  <button
                    key={model}
                    onClick={() => {
                      onChange(model);
                      setIsOpen(false);
                    }}
                    className={cn(
                      "w-full text-left p-3 font-mono text-xs flex items-center justify-between hover:bg-neutral-100 transition-colors border-b border-transparent",
                      value === model && "bg-[#FFF9E5] font-bold"
                    )}
                  >
                    <span className="truncate pr-4">{model}</span>
                    {value === model && <Check className="w-4 h-4 text-green-600" />}
                  </button>
                ))
              ) : (
                <div className="p-8 text-center opacity-40">
                  <p className="text-[10px] font-mono uppercase">无可用模型</p>
                  <p className="text-[9px] mt-1 italic">请点击“获取最新”或手动输入</p>
                </div>
              )}
            </div>

            {/* Manual Edit (Optional since the top input allows searching, but we might want to allow custom text) */}
            {search && !filteredModels.includes(search) && (
              <button
                onClick={() => {
                  onChange(search);
                  setIsOpen(false);
                }}
                className="p-3 bg-blue-50 border-t-2 border-[#141414] text-left hover:bg-blue-100"
              >
                <p className="text-[10px] font-mono opacity-50 uppercase">使用自定义名称:</p>
                <p className="font-mono text-xs font-bold truncate">{search}</p>
              </button>
            )}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
