import { apiClient } from "./client";
import type {
  AchievementCriteriaType,
  AdminAchievement,
  AdminEmergencyContact,
  AdminPaymentTransaction,
  AdminPin,
  AdminPinSuggestion,
  AdminQuest,
  AdminQuestChapter,
  AdminQuestUnlockRequirement,
  AdminReview,
  AdminRiskReport,
  AdminSosEvent,
  AdminStats,
  AdminUser,
  AdminUserRow,
  PaymentStatus,
  PinCategory,
  PinSuggestionStatus,
  UnlockRequirementType,
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

export interface CreatePinInput {
  name: string;
  category: PinCategory;
  description?: string;
  country: string;
  city?: string;
  lat: number;
  lng: number;
  photoUrls?: string[];
}

export async function createPin(body: CreatePinInput): Promise<AdminPin> {
  const { data } = await apiClient.post("/admin/pins", body);
  return data;
}

export async function fetchPinSuggestions(status?: PinSuggestionStatus): Promise<AdminPinSuggestion[]> {
  const { data } = await apiClient.get("/admin/pin-suggestions", { params: { status } });
  return data;
}

export async function approvePinSuggestion(id: string): Promise<{ suggestion: Partial<AdminPinSuggestion>; pin: AdminPin }> {
  const { data } = await apiClient.put(`/admin/pin-suggestions/${id}/approve`);
  return data;
}

export async function rejectPinSuggestion(id: string, reason?: string): Promise<AdminPinSuggestion> {
  const { data } = await apiClient.put(`/admin/pin-suggestions/${id}/reject`, { reason });
  return data;
}

export async function fetchQuests(): Promise<AdminQuest[]> {
  const { data } = await apiClient.get("/admin/quests");
  return data;
}

export interface CreateQuestInput {
  title: string;
  description?: string;
  questType: string;
  category?: string;
  chapterId?: string;
  chapterOrder?: number;
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

export async function fetchUnlockRequirements(questId: string): Promise<AdminQuestUnlockRequirement[]> {
  const { data } = await apiClient.get(`/admin/quests/${questId}/unlock-requirements`);
  return data;
}

export interface CreateUnlockRequirementInput {
  requirementType: UnlockRequirementType;
  minLevel?: number;
  requiredQuestId?: string;
  requiredPinId?: string;
  category?: string;
  country?: string;
  city?: string;
  countThreshold?: number;
}

export async function createUnlockRequirement(
  questId: string,
  body: CreateUnlockRequirementInput
): Promise<AdminQuestUnlockRequirement> {
  const { data } = await apiClient.post(`/admin/quests/${questId}/unlock-requirements`, body);
  return data;
}

export async function deleteUnlockRequirement(questId: string, requirementId: string): Promise<void> {
  await apiClient.delete(`/admin/quests/${questId}/unlock-requirements/${requirementId}`);
}

export async function fetchQuestChapters(): Promise<AdminQuestChapter[]> {
  const { data } = await apiClient.get("/admin/quest-chapters");
  return data;
}

export interface CreateQuestChapterInput {
  title: string;
  description?: string;
  orderIndex: number;
}

export async function createQuestChapter(body: CreateQuestChapterInput): Promise<AdminQuestChapter> {
  const { data } = await apiClient.post("/admin/quest-chapters", body);
  return data;
}

export async function updateQuestChapter(id: string, body: Partial<CreateQuestChapterInput>): Promise<AdminQuestChapter> {
  const { data } = await apiClient.put(`/admin/quest-chapters/${id}`, body);
  return data;
}

export async function deleteQuestChapter(id: string): Promise<void> {
  await apiClient.delete(`/admin/quest-chapters/${id}`);
}

export async function fetchAchievements(): Promise<AdminAchievement[]> {
  const { data } = await apiClient.get("/admin/achievements");
  return data;
}

export interface CreateAchievementInput {
  title: string;
  description?: string;
  iconUrl?: string;
  criteriaType: AchievementCriteriaType;
  criteriaCategory?: string;
  criteriaChapterId?: string;
  countThreshold?: number;
  xpReward: number;
  coinReward: number;
  isActive: boolean;
}

export async function createAchievement(body: CreateAchievementInput): Promise<AdminAchievement> {
  const { data } = await apiClient.post("/admin/achievements", body);
  return data;
}

export async function updateAchievement(id: string, body: Partial<CreateAchievementInput>): Promise<AdminAchievement> {
  const { data } = await apiClient.put(`/admin/achievements/${id}`, body);
  return data;
}

export async function deleteAchievement(id: string): Promise<void> {
  await apiClient.delete(`/admin/achievements/${id}`);
}

export async function grantAchievement(achievementId: string, userId: string): Promise<void> {
  await apiClient.post(`/admin/achievements/${achievementId}/grant`, { userId });
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
