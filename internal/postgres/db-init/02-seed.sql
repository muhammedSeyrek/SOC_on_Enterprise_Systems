-- ============================================================
-- 02-seed.sql
-- NAC kullanıcıları ve rol -> VLAN erişim profilleri
-- ============================================================

INSERT INTO access_profiles (role, vlan_id, profile_name)
VALUES
    ('admin',      10, 'admin'),
    ('employee',   20, 'employee'),
    ('guest',      30, 'guest'),
    ('quarantine', 99, 'quarantine')
ON CONFLICT (role) DO UPDATE SET
    vlan_id = EXCLUDED.vlan_id,
    profile_name = EXCLUDED.profile_name;

INSERT INTO users (username, role, cert_cn, status)
VALUES
    ('admin',    'admin',    'admin.nac.local',    'active'),
    ('employee', 'employee', 'employee.nac.local', 'active'),
    ('guest',    'guest',    'guest.nac.local',    'active')
ON CONFLICT (username) DO UPDATE SET
    role = EXCLUDED.role,
    cert_cn = EXCLUDED.cert_cn,
    status = EXCLUDED.status;