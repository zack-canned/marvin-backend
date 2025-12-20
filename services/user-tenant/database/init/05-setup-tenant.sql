CREATE OR REPLACE FUNCTION commons.setup_tenant(
    p_schema_name TEXT
)
RETURNS VOID AS $$
BEGIN
    -- 1. AGENTS: Configuration for specific AI personas
    EXECUTE format('
        CREATE TABLE %I.agents (
            id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name          VARCHAR(255) NOT NULL,
            model_id      VARCHAR(100) NOT NULL, -- e.g., "gpt-4o", "claude-3-5-sonnet"
            system_prompt TEXT,
            temperature   FLOAT DEFAULT 0.7,
            created_at    TIMESTAMPTZ DEFAULT NOW()
        )', p_schema_name);

    -- 2. MCP SERVERS: Model Context Protocol configurations
    EXECUTE format('
        CREATE TABLE %I.mcp_servers (
            id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            name           VARCHAR(255) UNIQUE NOT NULL,
            transport_type VARCHAR(50) NOT NULL, -- "stdio" or "sse"
            endpoint       TEXT NOT NULL,
            config_json    JSONB DEFAULT %L,
            is_active      BOOLEAN DEFAULT true
        )', p_schema_name, '{}'::jsonb);

    -- 3. KNOWLEDGE BASES (RAG): Files and Vector references
    EXECUTE format('
        CREATE TABLE %I.knowledge_sources (
            id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            file_name            TEXT NOT NULL,
            storage_path         TEXT NOT NULL, -- S3/Blob URL
            mime_type            VARCHAR(100),
            embedding_status     VARCHAR(50) DEFAULT %L, -- "pending", "indexed", "failed"
            vector_collection_id TEXT, -- Reference to an external Vector DB or pgvector
            created_at           TIMESTAMPTZ DEFAULT NOW()
        )', p_schema_name, 'pending');

    -- 4. CHAT HISTORY: Conversations and Messages
    EXECUTE format('
        CREATE TABLE %I.conversations (
            id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id    UUID NOT NULL,
            agent_id   UUID REFERENCES %I.agents(id) ON DELETE SET NULL,
            title      TEXT,
            created_at TIMESTAMPTZ DEFAULT NOW()
        )', p_schema_name, p_schema_name);

    EXECUTE format('
        CREATE TABLE %I.messages (
            id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            conversation_id UUID REFERENCES %I.conversations(id) ON DELETE CASCADE,
            role            VARCHAR(50) NOT NULL, -- "user", "assistant", "system", "tool"
            content         TEXT NOT NULL,
            tool_calls      JSONB, -- For MCP tool interactions
            token_count     INT,
            created_at      TIMESTAMPTZ DEFAULT NOW()
        )', p_schema_name, p_schema_name);

    EXECUTE format('
        CREATE TYPE %I.user_role AS ENUM (''admin'', ''member'', ''viewer'');
        CREATE TABLE %I.members (
            id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            global_user_id UUID NOT NULL, -- References commons.users(id)
            role           %I.user_role NOT NULL DEFAULT ''member'',
            joined_at      TIMESTAMPTZ DEFAULT NOW(),
            UNIQUE(global_user_id) -- A user has one role per tenant
        )', p_schema_name, p_schema_name, p_schema_name);

    -- 5. Set Permissions: Grant the app role access to these new tables
    EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA %I TO user_tenant_owner', p_schema_name);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
SET search_path = admin, pg_temp;

-- 2. Revoke all from public and grant only to the app role
REVOKE ALL ON FUNCTION commons.setup_tenant(TEXT) FROM PUBLIC;
