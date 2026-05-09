import React from 'react';
import { X, Check, Search } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

interface ModelPickerModalProps {
  isOpen: boolean;
  onClose: () => void;
  models: string[];
  onSelect: (model: string) => void;
  currentModel: string;
}

export function ModelPickerModal({ isOpen, onClose, models, onSelect, currentModel }: ModelPickerModalProps) {
  const [search, setSearch] = React.useState('');
  
  const filteredModels = models.filter(m => 
    m.toLowerCase().includes(search.toLowerCase())
  );

  return (
    <AnimatePresence>
      {isOpen && (
        <div className="fixed inset-0 z-[100] flex items-center justify-center p-4">
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={onClose}
            className="absolute inset-0 bg-[#141414]/60 backdrop-blur-sm"
          />
          
          <motion.div
            initial={{ scale: 0.9, opacity: 0, y: 20 }}
            animate={{ scale: 1, opacity: 1, y: 0 }}
            exit={{ scale: 0.9, opacity: 0, y: 20 }}
            className="relative w-full max-w-lg bg-white border-4 border-[#141414] shadow-[12px_12px_0px_0px_rgba(20,20,20,1)] overflow-hidden flex flex-col max-h-[80vh]"
          >
            {/* Header */}
            <div className="bg-[#141414] p-6 flex justify-between items-center shrink-0">
              <div className="flex items-center gap-3">
                <div className="w-3 h-3 rounded-full bg-[#FF3B30]" />
                <div className="w-3 h-3 rounded-full bg-[#FFCC00]" />
                <div className="w-3 h-3 rounded-full bg-[#4CD964]" />
                <h2 className="text-white font-black italic tracking-tighter ml-2">SELECT AI MODEL</h2>
              </div>
              <button 
                onClick={onClose}
                className="text-white hover:text-[#FF3B30] transition-colors"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            {/* Search Bar */}
            <div className="p-4 border-b-4 border-[#141414] shrink-0 bg-gray-50/50">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 opacity-40" />
                <input 
                  type="text"
                  placeholder="搜索模型名称..."
                  value={search}
                  onChange={(e) => setSearch(e.target.value)}
                  className="w-full pl-10 pr-4 py-2 bg-white border-2 border-[#141414] font-mono text-sm focus:outline-none focus:bg-[#FFF9E5]"
                />
              </div>
            </div>

            {/* Content List */}
            <div className="flex-1 overflow-y-auto p-4 custom-scrollbar">
              <div className="grid gap-2">
                {filteredModels.length > 0 ? (
                  filteredModels.map((model) => (
                    <button
                      key={model}
                      onClick={() => {
                        onSelect(model);
                        onClose();
                      }}
                      className={`
                        w-full text-left p-4 border-2 transition-all flex items-center justify-between group
                        ${currentModel === model 
                          ? 'border-[#141414] bg-[#FFE100] shadow-[4px_4px_0px_0px_rgba(20,20,20,1)]' 
                          : 'border-transparent hover:border-[#141414] hover:bg-gray-50'
                        }
                      `}
                    >
                      <span className="font-mono font-bold text-sm truncate pr-4">{model}</span>
                      {currentModel === model && <Check className="w-4 h-4 shrink-0" />}
                    </button>
                  ))
                ) : (
                  <div className="text-center py-12 opacity-40">
                    <p className="font-mono text-xs uppercase tracking-widest">No models found</p>
                  </div>
                )}
              </div>
            </div>

            {/* Footer Tip */}
            <div className="p-4 border-t-2 border-[#141414]/10 bg-gray-50 shrink-0">
               <p className="text-[10px] font-mono opacity-40 uppercase">Total: {models.length} Models Loaded</p>
            </div>
          </motion.div>
        </div>
      )}
    </AnimatePresence>
  );
}
