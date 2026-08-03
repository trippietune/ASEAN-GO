-- Schedule items become time-range events (start_time/end_time) instead of a
-- single scheduled_time, matching the mockup's itinerary view ("10:00-12:00").
ALTER TABLE schedule_items RENAME COLUMN scheduled_time TO start_time;
ALTER TABLE schedule_items ADD COLUMN end_time TIME;

ALTER TABLE schedule_items ADD CONSTRAINT schedule_items_time_range_valid
  CHECK (start_time IS NULL OR end_time IS NULL OR end_time > start_time);
