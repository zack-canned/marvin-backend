CREATE ROLE user_tenant_owner WITH
    LOGIN
    PASSWORD 'microservice';
COMMENT ON ROLE user_tenant_owner IS 'Main role for microservice connections to application data.';

CREATE SCHEMA commons AUTHORIZATION user_tenant_owner;
COMMENT ON SCHEMA commons IS 'Schema for common application data and tenant registry.';
GRANT ALL PRIVILEGES ON SCHEMA commons TO user_tenant_owner;

CREATE ROLE tenant_user WITH NOLOGIN;
COMMENT ON ROLE tenant_user IS 'Placeholder role for RLS policy enforcement.';
