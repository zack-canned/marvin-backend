CREATE TABLE commons.subscriptions (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id         UUID NOT NULL,
  user_id           UUID NOT NULL,
  subscription_type VARCHAR(50) NOT NULL,
  start_date        TIMESTAMPTZ DEFAULT NOW(),
  end_date          TIMESTAMPTZ,
  status            VARCHAR(50) NOT NULL,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT fk_tenant
    FOREIGN KEY (tenant_id)
      REFERENCES commons.tenant_registry (id),
  CONSTRAINT fk_user
    FOREIGN KEY (user_id)
      REFERENCES commons.users (id)
);

GRANT SELECT, INSERT, UPDATE, DELETE ON commons.subscriptions TO user_tenant_owner;
