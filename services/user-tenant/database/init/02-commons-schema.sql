CREATE SCHEMA commons;
COMMENT ON SCHEMA commons IS 'Schema for common application data and tenant registry.';

GRANT USAGE ON SCHEMA commons TO user_tenant_owner;
