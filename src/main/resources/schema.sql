-- Matches the Contact JPA entity (src/main/java/com/senthil/contacts/model/Contact.java)
-- exactly. Idempotent (IF NOT EXISTS) so it's safe to run on every startup, not just the
-- first. ddl-auto is deliberately "validate" in prod (see application-prod.yml) -- schema
-- changes are never auto-migrated by Hibernate; this file (run by Spring's SQL
-- initializer, before Hibernate's validation) is the one deliberate exception, and it
-- runs on every deploy, not as a one-off manual step.
CREATE TABLE IF NOT EXISTS contact (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(255)
);
