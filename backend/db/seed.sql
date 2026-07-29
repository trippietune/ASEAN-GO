-- Sample data for local development. Safe to re-run (guards on name/title uniqueness per country).

INSERT INTO verified_pins (name, category, description, country, city, location, is_verified, is_scam_alert, scam_alert_message, safety_score)
SELECT * FROM (VALUES
  ('Wat Arun', 'attraction', 'Iconic riverside temple, well-lit and patrolled in the evening.', 'Thailand', 'Bangkok', ST_MakePoint(100.4888, 13.7437)::geography, true, false, NULL::text, 92),
  ('Chatuchak Weekend Market', 'shop', 'Huge market, busy and generally safe but watch belongings.', 'Thailand', 'Bangkok', ST_MakePoint(100.5502, 13.7999)::geography, true, false, NULL::text, 75),
  ('Khao San Road (late night)', 'other', 'Reports of overpriced tuk-tuks and rigged card games after midnight.', 'Thailand', 'Bangkok', ST_MakePoint(100.4977, 13.7588)::geography, false, true, 'ระวังคนชวนเล่นไพ่หรือพาไปร้านที่ราคาสูงผิดปกติ', 30),
  ('Siam Paragon', 'shop', 'Upscale mall, high security presence.', 'Thailand', 'Bangkok', ST_MakePoint(100.5344, 13.7462)::geography, true, false, NULL::text, 95),
  ('Fake Gem Shop Cluster', 'shop', 'Multiple reports of a "closed temple" scam redirecting tourists here.', 'Thailand', 'Bangkok', ST_MakePoint(100.4930, 13.7510)::geography, false, true, 'ระวังคนบอกว่าวัดปิดแล้วชวนไปซื้อพลอย', 15)
) AS v(name, category, description, country, city, location, is_verified, is_scam_alert, scam_alert_message, safety_score)
WHERE NOT EXISTS (
  SELECT 1 FROM verified_pins p WHERE p.name = v.name AND p.country = v.country
);

INSERT INTO quests (title, description, quest_type, xp_reward, coin_reward, pin_id, country, active_until)
SELECT 'เช็คอินที่วัดอรุณ', 'ไปเช็คอินที่ Wat Arun เพื่อรับ XP', 'daily', 20, 5, p.id, 'Thailand', now() + interval '1 day'
FROM verified_pins p WHERE p.name = 'Wat Arun'
AND NOT EXISTS (SELECT 1 FROM quests WHERE title = 'เช็คอินที่วัดอรุณ');

INSERT INTO quests (title, description, quest_type, xp_reward, coin_reward, pin_id, country, active_until)
SELECT 'สำรวจตลาดจตุจักร', 'แวะไปที่ Chatuchak Weekend Market และเช็คอิน', 'daily', 15, 5, p.id, 'Thailand', now() + interval '1 day'
FROM verified_pins p WHERE p.name = 'Chatuchak Weekend Market'
AND NOT EXISTS (SELECT 1 FROM quests WHERE title = 'สำรวจตลาดจตุจักร');

INSERT INTO quests (title, description, quest_type, xp_reward, coin_reward, country, active_until)
SELECT 'อ่านประกาศเตือนภัยวันนี้', 'เปิดดูจุดเตือนภัย (Scam Alert) อย่างน้อย 1 จุดในแผนที่', 'daily', 10, 0, 'Thailand', now() + interval '1 day'
WHERE NOT EXISTS (SELECT 1 FROM quests WHERE title = 'อ่านประกาศเตือนภัยวันนี้');

INSERT INTO store_items (name, description, type, price, rarity, image_url)
SELECT * FROM (VALUES
  ('ชุดไทยพระราชนิยม', 'ชุดไทยสำหรับอวาตาร์ ใส่แล้วดูขลังสุดๆ', 'outfit', 150, 'rare', 'https://placehold.co/256x256?text=Thai+Outfit'),
  ('ชุดนักผจญภัย', 'ชุดลุยป่าสำหรับสายเดินทาง', 'outfit', 80, 'common', 'https://placehold.co/256x256?text=Explorer+Outfit'),
  ('อวาตาร์มังกรทอง', 'อวาตาร์พิเศษ หายาก', 'avatar', 400, 'legendary', 'https://placehold.co/256x256?text=Gold+Dragon'),
  ('อวาตาร์แมวส้ม', 'อวาตาร์น่ารักประจำวัน', 'avatar', 50, 'common', 'https://placehold.co/256x256?text=Orange+Cat'),
  ('บูสเตอร์ XP 2 เท่า (1 ชม.)', 'เพิ่ม XP เป็น 2 เท่าเป็นเวลา 1 ชั่วโมง', 'booster', 100, 'rare', 'https://placehold.co/256x256?text=XP+Booster'),
  ('บูสเตอร์เหรียญ 2 เท่า (1 ชม.)', 'เพิ่มเหรียญที่ได้รับเป็น 2 เท่าเป็นเวลา 1 ชั่วโมง', 'booster', 100, 'rare', 'https://placehold.co/256x256?text=Coin+Booster'),
  ('ของที่ระลึกวัดอรุณ', 'ของสะสมดิจิทัลจากการเช็คอินที่วัดอรุณ', 'souvenir', 30, 'common', 'https://placehold.co/256x256?text=Wat+Arun+Souvenir'),
  ('ของที่ระลึกจตุจักร', 'ของสะสมดิจิทัลจากตลาดจตุจักร', 'souvenir', 30, 'common', 'https://placehold.co/256x256?text=Chatuchak+Souvenir')
) AS v(name, description, type, price, rarity, image_url)
WHERE NOT EXISTS (
  SELECT 1 FROM store_items s WHERE s.name = v.name
);
