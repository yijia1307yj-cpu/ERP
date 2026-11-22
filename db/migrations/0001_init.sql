-- Up Migration

CREATE EXTENSION IF NOT EXISTS citext;

CREATE FUNCTION set_updated_at() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TABLE app_user (
  id                 uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  username           citext      NOT NULL UNIQUE,
  email              citext      UNIQUE,
  phone              text,
  password_hash      text        NOT NULL,
  status             text        NOT NULL DEFAULT 'active'
                                 CONSTRAINT app_user_status_check CHECK (status IN ('active', 'disabled')),
  failed_login_count int         NOT NULL DEFAULT 0,
  locked_until       timestamptz,
  is_platform_admin  boolean     NOT NULL DEFAULT false,
  last_login_at      timestamptz,
  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE org (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  code       text        NOT NULL UNIQUE
                         CONSTRAINT org_code_upper CHECK (code = upper(code)),
  name       text        NOT NULL,
  status     text        NOT NULL DEFAULT 'active'
                         CONSTRAINT org_status_check CHECK (status IN ('active', 'suspended', 'closed')),
  created_by uuid        REFERENCES app_user (id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE membership (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  org_id      uuid        NOT NULL REFERENCES org (id) ON DELETE CASCADE,
  user_id     uuid        NOT NULL REFERENCES app_user (id) ON DELETE CASCADE,
  role        text        NOT NULL DEFAULT 'member'
                          CONSTRAINT membership_role_check CHECK (role IN ('owner', 'admin', 'member')),
  status      text        NOT NULL DEFAULT 'pending'
                          CONSTRAINT membership_status_check
                          CHECK (status IN ('pending', 'active', 'rejected', 'removed')),
  invited_by  uuid        REFERENCES app_user (id) ON DELETE SET NULL,
  approved_by uuid        REFERENCES app_user (id) ON DELETE SET NULL,
  approved_at timestamptz,
  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT membership_org_id_user_id_key UNIQUE (org_id, user_id)
);

-- 一个组织只能有一个 owner：转让时须先降级旧 owner 再升级新 owner（同一事务）
CREATE UNIQUE INDEX membership_one_owner ON membership (org_id) WHERE role = 'owner';
CREATE INDEX membership_org_id_status_idx ON membership (org_id, status);
CREATE INDEX membership_user_id_idx ON membership (user_id);

CREATE TABLE refresh_token (
  id         uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid        NOT NULL REFERENCES app_user (id) ON DELETE CASCADE,
  token_hash text        NOT NULL UNIQUE,
  expires_at timestamptz NOT NULL,
  revoked_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX refresh_token_user_id_idx ON refresh_token (user_id);

-- 审计日志不加外键：组织/用户删除后记录仍需保留
CREATE TABLE audit_log (
  id         bigserial   PRIMARY KEY,
  org_id     uuid,
  actor_id   uuid,
  action     text        NOT NULL,
  target     text,
  ip         inet,
  ua         text,
  detail     jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX audit_log_org_id_created_at_idx ON audit_log (org_id, created_at DESC);
CREATE INDEX audit_log_created_at_idx ON audit_log (created_at DESC);

CREATE TRIGGER app_user_set_updated_at BEFORE UPDATE ON app_user
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER org_set_updated_at BEFORE UPDATE ON org
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER membership_set_updated_at BEFORE UPDATE ON membership
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Down Migration

DROP TABLE IF EXISTS audit_log;
DROP TABLE IF EXISTS refresh_token;
DROP TABLE IF EXISTS membership;
DROP TABLE IF EXISTS org;
DROP TABLE IF EXISTS app_user;
DROP FUNCTION IF EXISTS set_updated_at();
-- citext 扩展保留：CREATE 是 IF NOT EXISTS，且可能被其他对象使用
