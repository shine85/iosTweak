import { initializeApp } from 'firebase/app';
import { getAuth, GoogleAuthProvider, signInWithPopup, signInWithRedirect, signOut, getRedirectResult } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';

// 从环境变量读取配置 (Vite 会在编译时注入)
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET,
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
  firestoreDatabaseId: import.meta.env.VITE_FIREBASE_FIRESTORE_DATABASE_ID
};

const app = initializeApp(firebaseConfig);
export const auth = getAuth(app);
export const db = getFirestore(app, firebaseConfig.firestoreDatabaseId);
export const googleProvider = new GoogleAuthProvider();

export const loginWithGoogle = async () => {
  try {
    // 优先尝试 Popup，如果失败（比如被浏览器拦截），用户可以尝试 Redirect
    await signInWithPopup(auth, googleProvider);
  } catch (error: any) {
    console.error("Popup Login failed:", error);
    // 如果是关闭了窗口或者被拦截，我们抛出错误让 UI 处理或者引导使用 Redirect
    throw error;
  }
};

export const loginWithGoogleRedirect = () => signInWithRedirect(auth, googleProvider);
export const handleRedirectResult = () => getRedirectResult(auth);

export const logout = () => signOut(auth);
