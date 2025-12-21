CREATE TABLE commons.users (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id   UUID NOT NULL,
  email       VARCHAR(255) UNIQUE NOT NULL,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT fk_tenant
    FOREIGN KEY (tenant_id)
      REFERENCES commons.tenant_registry (id)
  );

GRANT SELECT, INSERT, UPDATE, DELETE ON commons.users TO user_tenant_owner;
