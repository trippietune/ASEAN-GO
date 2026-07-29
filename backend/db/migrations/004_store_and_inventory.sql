CREATE TABLE store_items (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL, -- 'outfit' | 'avatar' | 'booster' | 'souvenir'
  price INTEGER NOT NULL CHECK (price >= 0), -- price in coins
  rarity TEXT NOT NULL DEFAULT 'common', -- 'common' | 'rare' | 'epic' | 'legendary'
  image_url TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX store_items_type_idx ON store_items (type);
CREATE INDEX store_items_active_idx ON store_items (is_active);

CREATE TABLE inventory (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  item_id UUID NOT NULL REFERENCES store_items(id) ON DELETE CASCADE,
  acquired_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, item_id)
);

CREATE INDEX inventory_user_idx ON inventory (user_id);

CREATE TABLE coin_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL, -- positive = credited, negative = spent
  type TEXT NOT NULL, -- 'purchase' | 'quest_reward' | 'checkin_reward' | 'spend' | 'bonus'
  reference_id TEXT, -- questId, itemId, IAP package id, etc.
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX coin_transactions_user_idx ON coin_transactions (user_id, created_at DESC);
