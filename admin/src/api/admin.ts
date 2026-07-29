import { apiClient } from "./client";
import type {
  AdminEmergencyContact,
  AdminPaymentTransaction,
  AdminPin,
  AdminQuest,
  AdminReview,
  AdminRiskReport,
  AdminSosEvent,
  AdminStats,
  AdminUser,
  AdminUserRow,
  PaymentStatus,
  UserRole,
} from "./types";

export async function login(email: string, password: string): Promise<{ token: string; user: AdminUser }> {
  const { data } = await apiClient.post("/auth/login", { email, password });
  return data;
}

export async function fetchStats(): Promise<AdminStats> {
  const { data } = await apiClient.get("/admin/stats");
  return data;
}

export async function fetchPins(search?: string): Promise<AdminPin[]> {
  const { data } = await apiClient.get("/admin/pins", { params: { search } });
  return data;
}

export async function updatePin(id: string, body: Partial<{
  isVerified: boolean;
  isScamAlert: boolean;
  scamAlertMessage: string | null;
  safetyScore: number;
}>): Promise<AdminPin> {
  const { data } = await apiClient.put(`/admin/pins/${id}`, body);
  return data;
}

export async function deletePin(id: string): Promise<void> {
  await apiClient.delete(`/admin/pins/${id}`);
}

export async function fetchQuests(): Promise<AdminQuest[]> {
  const { data } = await apiClient.get("/admin/quests");
  return data;
}

export interface CreateQuestInput {
  title: string;
  description?: string;
  questType: string;
  xpReward: number;
  coinReward: number;
  pinId?: string;
  country?: string;
  activeUntil?: string;
}

export async function createQuest(body: CreateQuestInput): Promise<AdminQuest> {
  const { data } = await apiClient.post("/admin/quests", body);
  return data;
}

export async function updateQuest(id: string, body: Partial<CreateQuestInput>): Promise<AdminQuest> {
  const { data } = await apiClient.put(`/admin/quests/${id}`, body);
  return data;
}

export async function deleteQuest(id: string): Promise<void> {
  await apiClient.delete(`/admin/quests/${id}`);
}

export async function fetchUsers(search?: string): Promise<AdminUserRow[]> {
  const { data } = await apiClient.get("/admin/users", { params: { search } });
  return data;
}

export async function updateUserRole(id: string, role: UserRole): Promise<AdminUserRow> {
  const { data } = await apiClient.put(`/admin/users/${id}/role`, { role });
  return data;
}

export async function fetchReviews(): Promise<AdminReview[]> {
  const { data } = await apiClient.get("/admin/reviews");
  return data;
}

export async function deleteReview(id: string): Promise<void> {
  await apiClient.delete(`/admin/reviews/${id}`);
}

export async function fetchRiskReports(): Promise<AdminRiskReport[]> {
  const { data } = await apiClient.get("/admin/risk-reports");
  return data;
}

export async function deleteRiskReport(id: string): Promise<void> {
  await apiClient.delete(`/admin/risk-reports/${id}`);
}

export async function fetchSosEvents(status?: "active" | "resolved"): Promise<AdminSosEvent[]> {
  const { data } = await apiClient.get("/admin/sos-events", { params: { status } });
  return data;
}

export async function resolveSosEvent(id: string): Promise<AdminSosEvent> {
  const { data } = await apiClient.post(`/admin/sos-events/${id}/resolve`);
  return data;
}

export async function fetchEmergencyContacts(search?: string): Promise<AdminEmergencyContact[]> {
  const { data } = await apiClient.get("/admin/emergency-contacts", { params: { search } });
  return data;
}

export async function fetchPaymentTransactions(status?: PaymentStatus): Promise<AdminPaymentTransaction[]> {
  const { data } = await apiClient.get("/admin/payment-transactions", { params: { status } });
  return data;
}

export interface RefundResult {
  success: boolean;
  refundId: string;
  status: PaymentStatus;
  refundedAmountThb: number;
  coinsClawedBack: number;
  fullCoinsClawedBack: boolean;
}

export async function refundPaymentTransaction(id: string, amountThb?: number): Promise<RefundResult> {
  const { data } = await apiClient.post(`/admin/payment-transactions/${id}/refund`, { amountThb });
  return data;
}
