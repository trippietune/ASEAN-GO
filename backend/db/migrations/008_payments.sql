CREATE TABLE payment_transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider TEXT NOT NULL DEFAULT 'omise',
  provider_charge_id TEXT UNIQUE,
  package_id TEXT NOT NULL,
  coins INTEGER NOT NULL,
  amount_thb INTEGER NOT NULL, -- satang (smallest THB unit), matches Omise's 'amount'
  currency TEXT NOT NULL DEFAULT 'thb',
  status TEXT NOT NULL DEFAULT 'pending',
    -- 'pending' | 'successful' | 'failed' | 'refunded' | 'partially_refunded'
  coins_credited BOOLEAN NOT NULL DEFAULT FALSE,
  failure_code TEXT,
  failure_message TEXT,
  refunded_amount_thb INTEGER NOT NULL DEFAULT 0,
  metadata JSONB,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX payment_transactions_user_idx ON payment_transactions (user_id, created_at DESC);
CREATE INDEX payment_transactions_status_idx ON payment_transactions (status);
