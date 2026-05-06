import { initializeApp } from 'firebase/app';
import { getAuth, GoogleAuthProvider, signInWithPopup, signInWithRedirect, signOut, getRedirectResult } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import firebaseConfig from '../../firebase-applet-config.json';

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
