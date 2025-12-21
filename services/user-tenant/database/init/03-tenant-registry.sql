CREATE TABLE commons.tenant_registry (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_name   VARCHAR(255) UNIQUE NOT NULL,
  tenant_schema VARCHAR(255) UNIQUE NOT NULL,
  created_at    TIMESTAMPTZ DEFAULT NOW()
  );

GRANT SELECT, INSERT, UPDATE, DELETE ON commons.tenant_registry TO user_tenant_owner;
