# Database Design

## Overview
| Element | Description | Rationale |
| :--- | :--- | :--- |
| **Shared Database** | All tenants share the same physical PostgreSQL instance and database. | Easier to manage, lower infrastructure cost, and simpler maintenance/upgrades. |
| **Separate Schema** | Each Tenant gets its own dedicated PostgreSQL Schema (a namespace within the database). | **Strong Data Isolation**: Data for one tenant is logically separated from others. **Simplified Backup/Restore**: Can backup/restore a single tenant's schema. **Independent Schema Changes**: Allows for potential future flexibility in schema versions per tenant (if needed). |
| **Common Schema** | A single schema (e.g., public or a dedicated app_common schema) to store cross-tenant data. | Stores global application configuration, master data (e.g., country codes), and most importantly, the Tenant Registry (list of all tenants and their associated schemas/metadata). |

## User/Tenant Separation and Permissions
### TODO: Better understand if 1 and 2 are different strategies or one in the same.
The primary separation mechanisms are **Schemas** and **Permissions/RLS**.
1. Separtion via Schemas
    - **Tenant Registry**: Single table in a common location (i.e., `commons` schema) managing all tenants. This will be a switch gate for the server to appropriately connect to the correct schema for each tenant. (e.g., `tenants(id, name, schema)`).
    - **Microservice Connection**: Authenticates the use and deetermins the user's tenant `id`.
    - **Setting the Search Path**: Before executing any tenant-specific query, the microservice must dynamically set the PostgreSQL `search_path` to the tenant's schema. (e.g., `SET search_path TO 'tenant_<id>', 'commons', 'public';`). **Crucially, the `user_tenant_owner` role must only have permissions on the schemas it needs to access.**
2. Separtion via PostgreSQL Permissions (Roles)
    
    The `user_tenant_owner` role is key:
    - It should be granted `USAGE` on all tenant schemas
    - It should be granted `SELECT, INSERT, UPDATE, DELETE` on all necessary tables with those schemas
    
    **Principle of Least Privilege**: Do not grant `user_tentant_owner` role `CREATE` or `DROP` privileges. These are reserved for admin role.

## Key Abstraction Considerations
The primary goal of abstraction in this context is to **decouple the application code from the underlying multi-tenant implementation details**.
1. Tenant Context/Resolution Layer:

    This is the most critical abstraction. There is a **single** Tenant Context/Resolver service responsible for:
    - Accepting the authenticated user/request
    - Determining the tenant `id` and the associated `schema`
    - **Managing the database connection lifecycle**: It is responsible for calling `SET search_path TO ...` immediately after acquiring a connection from the pool, and ensuring the connection is returned correctly (or disconnected) afterwards.

2. Configuration Abstraction:

    **TODO**: Review below and see if that's needed - could it be stored in the tenant's schema? And applied after a connection?
    
    All tenant-specific metadata (e.g., feature flags, custom settings) should be retrieved from the common tenants table. The application should not need to know that these are stored in a common database; it just asks for the configuration for the current tenant.

    **Role/Permission Abstraction (good practice):**
    * Different classes of users (e.g., admin, manager, basic user) within a tenant should use a separate table (e.g., tenant_users) to store permissions. 
    * Avoid creating individual PostgreSQL roles for every application user. 
    * Stick to the `user_tenant_owner` or `tenant_user` roles and enforce fine-grained access checks in the application layer.

## Architecture

### Roles
* `marvin`
    - System Administrator/DBA role. Used for initial setup, migrations, backups, and managing other roles.
* `user_tenant_owner`
    - The **Microservice Connection Role**. The main role the microservice uses to connect to the database. It should have USAGE and SELECT/INSERT/UPDATE/DELETE on all common tables and tenant schemas.
* `tenant_user`
    - A placeholder/template role used in conjunction with Row-Level Security (RLS). All application users (after authentication) will effectively run queries with the permissions granted to this role. This role should only have SELECT permissions on the data it needs to access, and permissions should be enforced by RLS.
* `tenant_<id>_ro`
    - A Read-Only role that might be used by reporting or analytics microservices for a specific tenant.
