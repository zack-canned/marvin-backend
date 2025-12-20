CREATE ROLE user_tenant_owner WITH LOGIN PASSWORD 'microservice';
CREATE ROLE tenant_user WITH NOLOGIN;

CREATE SCHEMA commons;
COMMENT ON SCHEMA commons IS 'Schema for common application data and tenant registry.';

CREATE TABLE commons.tenant_registry
(
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_name   VARCHAR(255) UNIQUE NOT NULL,
    tenant_schema VARCHAR(255) UNIQUE NOT NULL
);

GRANT USAGE ON SCHEMA commons TO user_tenant_owner;
GRANT SELECT, INSERT, UPDATE, DELETE ON commons.tenant_registry TO user_tenant_owner;
