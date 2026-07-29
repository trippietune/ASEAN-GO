ALTER TABLE users
  ADD COLUMN notification_settings JSONB NOT NULL DEFAULT '{
    "pushNotifications": true,
    "emailNotifications": true,
    "safetyAlerts": true,
    "questReminders": true,
    "promotions": false
  }'::jsonb,
  ADD COLUMN privacy_settings JSONB NOT NULL DEFAULT '{
    "showProfileToOthers": true,
    "showCheckins": true,
    "showReviews": true,
    "allowDataCollection": true
  }'::jsonb;
