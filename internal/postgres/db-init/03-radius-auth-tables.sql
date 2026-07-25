-- FreeRADIUS PostgreSQL authorization tabloları

CREATE TABLE IF NOT EXISTS radcheck (
    id        BIGSERIAL PRIMARY KEY,
    username  VARCHAR(64) NOT NULL DEFAULT '',
    attribute VARCHAR(64) NOT NULL DEFAULT '',
    op        VARCHAR(2)  NOT NULL DEFAULT '==',
    value     VARCHAR(253) NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS idx_radcheck_username
    ON radcheck(username, attribute);

CREATE TABLE IF NOT EXISTS radreply (
    id        BIGSERIAL PRIMARY KEY,
    username  VARCHAR(64) NOT NULL DEFAULT '',
    attribute VARCHAR(64) NOT NULL DEFAULT '',
    op        VARCHAR(2)  NOT NULL DEFAULT '=',
    value     VARCHAR(253) NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS idx_radreply_username
    ON radreply(username, attribute);

CREATE TABLE IF NOT EXISTS radgroupcheck (
    id        BIGSERIAL PRIMARY KEY,
    groupname VARCHAR(64) NOT NULL DEFAULT '',
    attribute VARCHAR(64) NOT NULL DEFAULT '',
    op        VARCHAR(2)  NOT NULL DEFAULT '==',
    value     VARCHAR(253) NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS idx_radgroupcheck_groupname
    ON radgroupcheck(groupname, attribute);

CREATE TABLE IF NOT EXISTS radgroupreply (
    id        BIGSERIAL PRIMARY KEY,
    groupname VARCHAR(64) NOT NULL DEFAULT '',
    attribute VARCHAR(64) NOT NULL DEFAULT '',
    op        VARCHAR(2)  NOT NULL DEFAULT '=',
    value     VARCHAR(253) NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS idx_radgroupreply_groupname
    ON radgroupreply(groupname, attribute);

CREATE TABLE IF NOT EXISTS radusergroup (
    username  VARCHAR(64) NOT NULL DEFAULT '',
    groupname VARCHAR(64) NOT NULL DEFAULT '',
    priority  INTEGER NOT NULL DEFAULT 0,
    PRIMARY KEY (username, groupname)
);

CREATE INDEX IF NOT EXISTS idx_radusergroup_username
    ON radusergroup(username);
