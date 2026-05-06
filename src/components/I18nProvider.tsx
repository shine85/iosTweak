import React, { createContext, useContext, useState, useEffect } from 'react';
import zh from '../locales/zh.json';
import en from '../locales/en.json';

type Locale = 'zh' | 'en';
type Translations = typeof zh;

interface I18nContextType {
  locale: Locale;
  setLocale: (locale: Locale) => void;
  t: (key: string, params?: Record<string, string>) => string;
}

const I18nContext = createContext<I18nContextType | undefined>(undefined);

const translations: Record<Locale, any> = { zh, en };

export const I18nProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [locale, setLocale] = useState<Locale>(() => {
    const saved = localStorage.getItem('app_locale');
    if (saved === 'zh' || saved === 'en') return saved;
    return 'zh';
  });

  useEffect(() => {
    localStorage.setItem('app_locale', locale);
  }, [locale]);

  const t = (path: string, params?: Record<string, string>) => {
    const keys = path.split('.');
    let result = translations[locale];
    
    for (const key of keys) {
      if (result[key] === undefined) return path;
      result = result[key];
    }

    if (typeof result !== 'string') return path;

    if (params) {
      Object.entries(params).forEach(([key, value]) => {
        result = result.replace(`{${key}}`, value);
      });
    }

    return result;
  };

  return (
    <I18nContext.Provider value={{ locale, setLocale, t }}>
      {children}
    </I18nContext.Provider>
  );
};

export const useI18n = () => {
  const context = useContext(I18nContext);
  if (context === undefined) {
    throw new Error('useI18n must be used within an I18nProvider');
  }
  return context;
};
