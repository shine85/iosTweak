import React, { createContext, useContext, useEffect, useState } from 'react';
import { auth, loginWithGoogle, loginWithGoogleRedirect, handleRedirectResult, logout as firebaseLogout } from '../lib/firebase';
import { onAuthStateChanged, User } from 'firebase/auth';
import { LogIn, LogOut, ShieldAlert, AlertCircle, ExternalLink } from 'lucide-react';

export const logout = firebaseLogout;

interface AuthContextType {
  user: User | null;
  loading: boolean;
  isAdmin: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

// 允许访问的管理员邮箱
const ADMIN_EMAILS = ['hanhui7413@gmail.com']; 

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    // 处理重定向返回的结果
    handleRedirectResult()
      .then((result) => {
        if (result) {
          console.log("Redirect login success:", result.user);
        }
      })
      .catch((err) => {
        console.error("Redirect login error:", err);
        if (err.code === 'auth/unauthorized-domain') {
          setError(`域名未授权。请在 Firebase 控制台添加此域名：${window.location.hostname}`);
        } else {
          setError(err.message);
        }
      });

    const unsubscribe = onAuthStateChanged(auth, (user) => {
      setUser(user);
      setLoading(false);
    });
    return unsubscribe;
  }, []);

  const isAdmin = !!user?.email && ADMIN_EMAILS.includes(user.email);

  if (loading) {
    return (
      <div className="min-h-screen bg-[#E4E3E0] flex items-center justify-center">
        <div className="text-center animate-pulse">
            <div className="w-12 h-12 border-4 border-[#141414] border-t-transparent rounded-full animate-spin mx-auto mb-4"></div>
            <p className="font-mono text-sm uppercase tracking-widest opacity-50">系统初始化中...</p>
        </div>
      </div>
    );
  }

  if (!user) {
    return <LoginScreen error={error} setError={setError} />;
  }

  if (!isAdmin) {
    return (
      <div className="min-h-screen bg-[#E4E3E0] flex items-center justify-center p-8">
        <div className="max-w-md w-full bg-white border-2 border-[#141414] p-8 text-center space-y-6">
          <ShieldAlert className="w-16 h-16 text-red-500 mx-auto" />
          <h1 className="text-2xl font-bold">权限不足</h1>
          <p className="text-sm opacity-70">
            您的账号 ({user.email}) 不在管理员白名单中。请联系管理员添加权限。
          </p>
          <button 
            onClick={logout}
            className="w-full h-12 border-2 border-[#141414] hover:bg-black hover:text-white transition-all font-bold flex items-center justify-center gap-2"
          >
            <LogOut className="w-4 h-4" />
            切换账号
          </button>
        </div>
      </div>
    );
  }

  return (
    <AuthContext.Provider value={{ user, loading, isAdmin }}>
      {children}
    </AuthContext.Provider>
  );
};

const LoginScreen = ({ error, setError }: { error: string | null, setError: (e: string | null) => void }) => {
  const [isLoggingIn, setIsLoggingIn] = useState(false);

  const handleLogin = async (mode: 'popup' | 'redirect') => {
    setIsLoggingIn(true);
    setError(null);
    try {
      if (mode === 'popup') {
        await loginWithGoogle();
      } else {
        await loginWithGoogleRedirect();
      }
    } catch (err: any) {
      console.error("Login attempt failed:", err);
      if (err.code === 'auth/popup-blocked') {
        setError("登录窗口被浏览器拦截，请允许弹出窗口或使用重定向模式。");
      } else if (err.code === 'auth/unauthorized-domain') {
        setError(`域名未授权。请在 Firebase 控制台添加此域名：${window.location.hostname}`);
      } else {
        setError(err.message || "登录失败，请稍后重试。");
      }
    } finally {
      setIsLoggingIn(false);
    }
  };

  return (
    <div className="min-h-screen bg-[#E4E3E0] flex items-center justify-center p-8">
      <div className="max-w-md w-full bg-white border-4 border-[#141414] p-10 shadow-[8px_8px_0px_0px_rgba(20,20,20,1)] flex flex-col items-center gap-8">
        <div className="text-center">
            <h1 className="text-4xl font-black italic tracking-tighter mb-2">iOS TWEAK STUDIO</h1>
            <p className="text-[10px] font-mono opacity-50 uppercase tracking-[0.2em] underline decoration-blue-500 decoration-2 underline-offset-4">Secure Admin Terminal v1.2.0</p>
        </div>

        {error && (
          <div className="w-full p-4 bg-red-50 border-l-4 border-red-500 flex gap-3 items-start animate-shake">
            <AlertCircle className="w-5 h-5 text-red-500 shrink-0 mt-0.5" />
            <div className="space-y-1">
              <p className="text-xs font-bold text-red-800">登录出错</p>
              <p className="text-[10px] text-red-600 leading-tight">{error}</p>
            </div>
          </div>
        )}

        <div className="w-full space-y-4">
            <p className="text-sm text-center leading-relaxed opacity-70 mb-2">
                这是一个受限制的开发终端。请使用授权的 Google 账号登录以访问云编译与 Tweak 管理平台。
            </p>
            
            <button 
                onClick={() => handleLogin('popup')}
                disabled={isLoggingIn}
                className="w-full h-14 bg-[#141414] text-white font-bold text-lg hover:bg-neutral-800 transition-all flex items-center justify-center gap-3 active:translate-y-1 active:shadow-none disabled:opacity-50"
            >
                {isLoggingIn ? <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" /> : <LogIn className="w-5 h-5" />}
                使用 Google 账号登录
            </button>

            <div className="relative py-2 flex items-center justify-center">
              <div className="absolute inset-0 flex items-center"><div className="w-full border-t border-black/10"></div></div>
              <span className="relative bg-white px-2 text-[10px] uppercase tracking-widest opacity-30 font-bold">或者</span>
            </div>

            <button 
                onClick={() => handleLogin('redirect')}
                disabled={isLoggingIn}
                className="w-full h-10 border-2 border-[#141414] font-bold text-xs hover:bg-[#141414] hover:text-white transition-all flex items-center justify-center gap-2 disabled:opacity-50"
            >
                <ExternalLink className="w-3 h-3" />
                使用重定向模式登录 (更稳定)
            </button>
        </div>

        <div className="pt-6 border-t border-black/10 w-full text-center">
            <p className="text-[9px] font-mono opacity-40 uppercase">Authorized Access Only. All transactions recorded.</p>
        </div>
      </div>
    </div>
  );
};

export const useAuth = () => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
