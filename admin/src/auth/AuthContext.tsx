import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from "react";
import * as adminApi from "../api/admin";
import { clearToken, getToken, setToken, setUnauthorizedHandler } from "../api/client";
import type { AdminUser } from "../api/types";

interface AuthContextValue {
  user: AdminUser | null;
  isLoading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | null>(null);

const USER_KEY = "aseango_admin_user";

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AdminUser | null>(null);
  const [isLoading, setIsLoading] = useState(true);

  const logout = useCallback(() => {
    clearToken();
    localStorage.removeItem(USER_KEY);
    setUser(null);
  }, []);

  useEffect(() => {
    setUnauthorizedHandler(logout);
    const token = getToken();
    const storedUser = localStorage.getItem(USER_KEY);
    if (token && storedUser) {
      try {
        setUser(JSON.parse(storedUser) as AdminUser);
      } catch {
        logout();
      }
    }
    setIsLoading(false);
  }, [logout]);

  const login = useCallback(async (email: string, password: string) => {
    const { token, user: loggedInUser } = await adminApi.login(email, password);
    if (loggedInUser.role !== "admin" && loggedInUser.role !== "moderator") {
      throw new Error("บัญชีนี้ไม่มีสิทธิ์เข้าถึง Admin Dashboard");
    }
    setToken(token);
    localStorage.setItem(USER_KEY, JSON.stringify(loggedInUser));
    setUser(loggedInUser);
  }, []);

  return (
    <AuthContext.Provider value={{ user, isLoading, login, logout }}>{children}</AuthContext.Provider>
  );
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
