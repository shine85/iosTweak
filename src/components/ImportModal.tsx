import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Upload, X, Code2, AlertTriangle } from 'lucide-react';

interface ImportModalProps {
  isOpen: boolean;
  onClose: () => void;
  onImport: (code: string) => void;
}

export const ImportModal: React.FC<ImportModalProps> = ({ isOpen, onClose, onImport }) => {
  const [code, setCode] = useState('');

  if (!isOpen) return null;

  return (
    <AnimatePresence>
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-6 bg-black/80 backdrop-blur-sm">
        <motion.div
          initial={{ scale: 0.9, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          exit={{ scale: 0.9, opacity: 0 }}
          className="bg-white border-4 border-[#141414] shadow-[12px_12px_0px_0px_rgba(20,20,20,1)] w-full max-w-4xl max-h-[90vh] flex flex-col"
        >
          {/* Header */}
          <div className="border-b-4 border-[#141414] p-4 flex items-center justify-between bg-blue-500">
            <div className="flex items-center gap-3">
              <Upload className="w-6 h-6 text-white" strokeWidth={3} />
              <h2 className="text-xl font-black text-white italic uppercase tracking-tight">导入外部 Logos 源码 (.xm)</h2>
            </div>
            <button 
              onClick={onClose}
              className="p-1 hover:bg-white/20 transition-colors rounded"
            >
              <X className="w-6 h-6 text-white" strokeWidth={3} />
            </button>
          </div>

          {/* Content */}
          <div className="p-6 flex-1 overflow-y-auto space-y-4">
            <div className="bg-yellow-100 border-2 border-yellow-400 p-4 flex items-start gap-3">
              <AlertTriangle className="w-5 h-5 text-yellow-700 mt-0.5 flex-shrink-0" />
              <p className="text-xs font-bold text-yellow-800">
                注意：导入源码将覆盖当前编辑器中的内容。请确保您粘贴的是完整的 .xm (Logos) 语法代码。系统会自动尝试维持基本的 Makefile 结构。
              </p>
            </div>

            <div className="relative group">
              <div className="absolute top-4 left-4 flex items-center gap-2 pointer-events-none opacity-20">
                <Code2 className="w-6 h-6" />
                <span className="text-sm font-mono font-bold tracking-widest">PASTE SOURCE CODE HERE...</span>
              </div>
              <textarea
                value={code}
                onChange={(e) => setCode(e.target.value)}
                placeholder=""
                className="w-full h-80 bg-gray-50 border-4 border-[#141414] p-4 font-mono text-sm focus:bg-white focus:outline-none transition-colors resize-none placeholder:opacity-50"
                spellCheck={false}
              />
            </div>
          </div>

          {/* Footer */}
          <div className="p-4 border-t-4 border-[#141414] bg-gray-100 flex justify-end gap-4">
            <button
              onClick={onClose}
              className="px-6 py-2 font-black border-4 border-[#141414] hover:bg-gray-200 transition-all uppercase text-sm"
            >
              取消
            </button>
            <button
              onClick={() => {
                if (code.trim()) {
                  onImport(code);
                  onClose();
                  setCode('');
                }
              }}
              disabled={!code.trim()}
              className="px-8 py-2 font-black bg-[#141414] text-white hover:bg-[#2a2a2a] disabled:opacity-50 disabled:cursor-not-allowed transform hover:-translate-y-1 active:translate-y-0 transition-all uppercase text-sm"
            >
              确认导入
            </button>
          </div>
        </motion.div>
      </div>
    </AnimatePresence>
  );
};
