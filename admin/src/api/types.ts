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

export type QuestType = "daily" | "weekly" | "recommended";

export interface AdminQuest {
  id: string;
  title: string;
  description: string | null;
  quest_type: QuestType;
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
