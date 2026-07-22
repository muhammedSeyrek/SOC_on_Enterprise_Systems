-- ============================================================
-- 01-schema.sql
-- FreeRADIUS mods-enabled/sql modülünün beklediği standart tablolar
-- + projeye özel users/access_profiles/auth_logs tabloları
-- ============================================================

CREATE TABLE radacct (
    radacctid       BIGSERIAL PRIMARY KEY,
    acctsessionid   VARCHAR(64) NOT NULL,
    acctuniqueid    VARCHAR(32) NOT NULL UNIQUE,
    username        VARCHAR(64),
    realm           VARCHAR(64),
    nasipaddress    INET NOT NULL,
    nasportid       VARCHAR(32),
    nasporttype     VARCHAR(32),
    acctstarttime   TIMESTAMPTZ,
    acctupdatetime  TIMESTAMPTZ,
    acctstoptime    TIMESTAMPTZ,
    acctinterval    BIGINT,
    acctsessiontime BIGINT,
    acctauthentic   VARCHAR(32),
    connectinfo_start VARCHAR(128),
    connectinfo_stop  VARCHAR(128),
    acctinputoctets   BIGINT,
    acctoutputoctets  BIGINT,
    calledstationid  VARCHAR(64),
    callingstationid VARCHAR(64),
    acctterminatecause VARCHAR(64),
    servicetype      VARCHAR(32),
    framedprotocol   VARCHAR(32),
    framedipaddress  INET
);

CREATE TABLE radpostauth (
    id          BIGSERIAL PRIMARY KEY,
    username    VARCHAR(64) NOT NULL,
    pass        VARCHAR(64),
    reply       VARCHAR(32) NOT NULL,
    authdate    TIMESTAMPTZ NOT NULL DEFAULT now(),
    class       VARCHAR(64)
);

CREATE TABLE users (
    id          SERIAL PRIMARY KEY,
    username    VARCHAR(64) NOT NULL UNIQUE,
    role        VARCHAR(32) NOT NULL,
    cert_cn     VARCHAR(128) NOT NULL UNIQUE,
    status      VARCHAR(16) NOT NULL DEFAULT 'active'
);

CREATE TABLE access_profiles (
    role         VARCHAR(32) PRIMARY KEY,
    vlan_id      INTEGER NOT NULL,
    profile_name VARCHAR(64) NOT NULL
);

CREATE TABLE auth_logs (
    id            BIGSERIAL PRIMARY KEY,
    ts            TIMESTAMPTZ NOT NULL DEFAULT now(),
    identity      VARCHAR(128) NOT NULL,
    method        VARCHAR(16) NOT NULL,
    source_ip     INET,
    result        VARCHAR(16) NOT NULL,
    reason        VARCHAR(255),
    vlan_assigned INTEGER
);

CREATE INDEX idx_radacct_username ON radacct(username);
CREATE INDEX idx_radpostauth_username ON radpostauth(username);
CREATE INDEX idx_auth_logs_identity ON auth_logs(identity);
CREATE INDEX idx_auth_logs_ts ON auth_logs(ts);
