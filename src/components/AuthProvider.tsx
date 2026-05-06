import React, { createContext, useContext, useEffect, useState } from 'react';
import { auth, loginWithGoogle, logout as firebaseLogout } from '../lib/firebase';
import { onAuthStateChanged, User } from 'firebase/auth';
import { LogIn, LogOut, ShieldAlert } from 'lucide-react';

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

  useEffect(() => {
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
    return <LoginScreen />;
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

const LoginScreen = () => {
  return (
    <div className="min-h-screen bg-[#E4E3E0] flex items-center justify-center p-8">
      <div className="max-w-md w-full bg-white border-4 border-[#141414] p-10 shadow-[8px_8px_0px_0px_rgba(20,20,20,1)] flex flex-col items-center gap-8">
        <div className="text-center">
            <h1 className="text-4xl font-black italic tracking-tighter mb-2">iOS TWEAK STUDIO</h1>
            <p className="text-[10px] font-mono opacity-50 uppercase tracking-[0.2em] underline decoration-blue-500 decoration-2 underline-offset-4">Secure Admin Terminal v1.2.0</p>
        </div>

        <div className="w-full space-y-4">
            <p className="text-sm text-center leading-relaxed opacity-70 mb-6">
                这是一个受限制的开发终端。请使用授权的 Google 账号登录以访问云编译与 Tweak 管理平台。
            </p>
            <button 
                onClick={loginWithGoogle}
                className="w-full h-14 bg-[#141414] text-white font-bold text-lg hover:bg-neutral-800 transition-all flex items-center justify-center gap-3 active:translate-y-1 active:shadow-none"
            >
                <LogIn className="w-5 h-5" />
                使用 Google 账号登录
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
