-- 1. Must be executed as 'marvin' (the Admin)
-- This function encapsulates the "Higher Privilege" logic
CREATE OR REPLACE FUNCTION commons.provision_tenant(
    p_tenant_name TEXT
)
RETURNS VOID AS $$
DECLARE
    v_tenant_name TEXT;
    v_schema_name  TEXT;
BEGIN
    -- A1. Validate inputs to prevent malicious schema names
    v_tenant_name := TRIM(regexp_replace(p_tenant_name, '[\x00-\x1F\x7F]', '', 'g'));
    v_schema_name := LOWER(
        TRIM(BOTH '_' FROM 
            REGEXP_REPLACE(
                REGEXP_REPLACE(
                    REGEXP_REPLACE(v_tenant_name, '([a-z0-9])([A-Z])', '\1_\2', 'g'),
                    '[^a-zA-Z0-9]+', '_', 'g'
                ), 
                '_+', '_', 'g'
            )
        )
    );

    -- A2. Ensure schema name isn't empty after cleaning
    IF v_schema_name = '' THEN
        RAISE EXCEPTION 'Invalid tenant name: result resulted in empty schema identifier';
    END IF;
    -- A3. Ensure schema name isn't reserved
    IF v_schema_name LIKE 'pg_%' OR v_schema_name = 'information_schema' THEN
        RAISE EXCEPTION 'Reserved schema name: %', v_schema_name;
    END IF;

    -- B. Insert into the registry (marvin owns this, so he can write to it)
    INSERT INTO commons.tenant_registry (tenant_name, tenant_schema)
    VALUES (v_tenant_name, v_schema_name);

    -- C. Create the schema dynamically
    -- quote_ident is CRITICAL to prevent SQL Injection
    EXECUTE 'CREATE SCHEMA ' || quote_ident(v_schema_name);

    -- D. Set up permissions for the App Role on this NEW schema
    --EXECUTE FORMAT('GRANT USAGE, CREATE ON SCHEMA %I TO user_tenant_owner', v_schema_name);
    EXECUTE 'GRANT USAGE, CREATE ON SCHEMA ' || quote_ident(v_schema_name) || ' TO user_tenant_owner';

    -- E. Create base tables inside the new schema
    PERFORM commons.setup_tenant(v_schema_name);

    -- F. Enable RLS Features
    EXECUTE 'ALTER TABLE ' || quote_ident(v_schema_name) || '.conversations ENABLE ROW LEVEL SECURITY;';

    -- TODO: Set up a 'app.current_user_id' variable and implement the following
    -- EXECUTE format('
    --     CREATE POLICY tenant_user_isolation_policy ON %I.conversations
    --     USING (
    --         user_id = (current_setting(''app.current_user_id'')::uuid)
    --         OR 
    --         EXISTS (
    --             SELECT 1 FROM %I.members 
    --             WHERE global_user_id = (current_setting(''app.current_user_id'')::uuid) 
    --             AND role = ''admin''
    --         )
    -- );', p_schema_name, p_schema_name, p_schema_name);

    RAISE NOTICE 'Tenant % provisioned with schema %', v_tenant_name, v_schema_name;

END;
$$ LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = admin, pg_temp; -- Security best practice for SecDef functions

-- 2. Revoke all from public and grant only to the app role
REVOKE ALL ON FUNCTION commons.provision_tenant(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION commons.provision_tenant(TEXT) TO user_tenant_owner;
