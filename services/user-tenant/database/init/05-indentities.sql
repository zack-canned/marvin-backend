CREATE TABLE commons.indentities (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id     UUID NOT NULL,
  user_id       UUID,
  provider      VARCHAR,
  provider_id   VARCHAR,
  password_hash TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT fk_tenant
    FOREIGN KEY (tenant_id)
      REFERENCES commons.tenant_registry (id),
  CONSTRAINT fk_user
      FOREIGN KEY (user_id)
        REFERENCES commons.users (id)
  );

GRANT SELECT, INSERT, UPDATE, DELETE ON commons.indentities TO user_tenant_owner;
