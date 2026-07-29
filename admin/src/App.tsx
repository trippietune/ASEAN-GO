import { ConfigProvider } from "antd";
import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { AuthProvider } from "./auth/AuthContext";
import RequireAuth from "./auth/RequireAuth";
import AdminLayout from "./layout/AdminLayout";
import LoginPage from "./pages/LoginPage";
import StatsPage from "./pages/StatsPage";
import PinsPage from "./pages/PinsPage";
import QuestsPage from "./pages/QuestsPage";
import UsersPage from "./pages/UsersPage";
import ReviewsPage from "./pages/ReviewsPage";
import SafetyPage from "./pages/SafetyPage";
import EmergencyContactsPage from "./pages/EmergencyContactsPage";
import PaymentsPage from "./pages/PaymentsPage";

export default function App() {
  return (
    <ConfigProvider theme={{ token: { colorPrimary: "#eb5a7d" } }}>
      <BrowserRouter>
        <AuthProvider>
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route
              element={
                <RequireAuth>
                  <AdminLayout />
                </RequireAuth>
              }
            >
              <Route path="/" element={<StatsPage />} />
              <Route path="/pins" element={<PinsPage />} />
              <Route path="/quests" element={<QuestsPage />} />
              <Route path="/users" element={<UsersPage />} />
              <Route path="/reviews" element={<ReviewsPage />} />
              <Route path="/safety" element={<SafetyPage />} />
              <Route path="/emergency-contacts" element={<EmergencyContactsPage />} />
              <Route path="/payments" element={<PaymentsPage />} />
            </Route>
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </AuthProvider>
      </BrowserRouter>
    </ConfigProvider>
  );
}
