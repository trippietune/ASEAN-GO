ALTER TABLE users
  ADD COLUMN role TEXT NOT NULL DEFAULT 'user'
    CHECK (role IN ('user', 'admin', 'moderator'));

CREATE INDEX users_role_idx ON users (role) WHERE role != 'user';
