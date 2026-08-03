export type UserRole = "user" | "admin" | "moderator";

export interface AdminUser {
  id: string;
  email: string;
  display_name: string;
  auth_provider: string;
  avatar_url: string | null;
  xp: number;
  level: number;
  is_premium: boolean;
  coin_balance: number;
  role: UserRole;
}

export interface AdminUserRow {
  id: string;
  email: string;
  display_name: string;
  role: UserRole;
  auth_provider: string;
  xp: number;
  level: number;
  is_premium: boolean;
  coin_balance: number;
  created_at: string;
}

export interface AdminStats {
  users: { total: number; new_this_week: number };
  pins: { total: number; verified: number };
  quests: { total: number };
  reviews: { total: number; average_rating: number };
  activeSosEvents: number;
  riskReports: number;
  scamAlerts: number;
}

export type PinCategory = "food" | "shop" | "attraction" | "transport" | "lodging" | "other";

export interface AdminPin {
  id: string;
  name: string;
  category: PinCategory;
  country: string;
  city: string | null;
  lat: number;
  lng: number;
  is_verified: boolean;
  is_scam_alert: boolean;
  scam_alert_message: string | null;
  safety_score: number;
  submitted_by: string | null;
  submitted_by_name: string | null;
  created_at: string;
  review_count: number;
  report_count: number;
}

export type PinSuggestionStatus = "pending" | "approved" | "rejected";

export interface AdminPinSuggestion {
  id: string;
  name: string;
  category: PinCategory;
  description: string | null;
  country: string;
  city: string | null;
  lat: number;
  lng: number;
  photo_urls: string[];
  submitted_by: string;
  submitted_by_name: string | null;
  status: PinSuggestionStatus;
  reviewed_by: string | null;
  reviewed_at: string | null;
  rejection_reason: string | null;
  resulting_pin_id: string | null;
  created_at: string;
}

export type QuestType = "daily" | "location" | "category" | "level" | "story";

export interface AdminQuest {
  id: string;
  title: string;
  description: string | null;
  quest_type: QuestType;
  category: string | null;
  chapter_id: string | null;
  chapter_order: number | null;
  xp_reward: number;
  coin_reward: number;
  pin_id: string | null;
  pin_name: string | null;
  country: string | null;
  active_from?: string;
  active_until: string | null;
  created_at: string;
  completed_count: number;
}

export interface AdminQuestChapter {
  id: string;
  title: string;
  description: string | null;
  order_index: number;
  quest_count: number;
  created_at: string;
  updated_at: string;
}

export type UnlockRequirementType = "level" | "quest" | "checkin" | "category" | "location";

export type AchievementCriteriaType =
  | "quests_completed"
  | "checkins"
  | "level_reached"
  | "category_visits"
  | "chapter_completed"
  | "manual";

export interface AdminAchievement {
  id: string;
  title: string;
  description: string | null;
  icon_url: string | null;
  criteria_type: AchievementCriteriaType;
  criteria_category: string | null;
  criteria_chapter_id: string | null;
  count_threshold: number | null;
  xp_reward: number;
  coin_reward: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}

export interface AdminQuestUnlockRequirement {
  id: string;
  quest_id: string;
  requirement_type: UnlockRequirementType;
  min_level: number | null;
  required_quest_id: string | null;
  required_pin_id: string | null;
  category: string | null;
  country: string | null;
  city: string | null;
  count_threshold: number | null;
  source: "admin" | "chapter_auto";
  created_at: string;
}

export interface AdminReview {
  id: string;
  pin_id: string;
  pin_name: string;
  user_id: string;
  user_display_name: string;
  rating: number;
  comment: string | null;
  photo_urls: string[];
  created_at: string;
}

export type RiskSeverity = "caution" | "warning" | "danger";

export interface AdminRiskReport {
  id: string;
  pin_id: string;
  pin_name: string;
  reported_by: string;
  reporter_display_name: string;
  severity: RiskSeverity;
  description: string;
  created_at: string;
}

export interface AdminSosEvent {
  id: string;
  user_id: string;
  user_display_name: string;
  emergency_contact_name: string | null;
  emergency_contact_phone: string | null;
  lat: number;
  lng: number;
  status: "active" | "resolved";
  created_at: string;
  resolved_at: string | null;
}

export interface AdminEmergencyContact {
  id: string;
  email: string;
  display_name: string;
  emergency_contact_name: string;
  emergency_contact_phone: string;
}

export type PaymentStatus = "pending" | "successful" | "failed" | "refunded" | "partially_refunded";

export interface AdminPaymentTransaction {
  id: string;
  user_id: string;
  user_display_name: string;
  user_email: string;
  provider: string;
  provider_charge_id: string | null;
  package_id: string;
  coins: number;
  amount_thb: number; // satang
  currency: string;
  status: PaymentStatus;
  coins_credited: boolean;
  failure_code: string | null;
  failure_message: string | null;
  refunded_amount_thb: number; // satang
  created_at: string;
  updated_at: string;
}
