-- Tài khoản bị khóa phiên do "Too many authentication failures"
SELECT username, COUNT(*) AS so_lan FROM logs
WHERE event_type='too_many_auth_failures' GROUP BY username ORDER BY so_lan DESC LIMIT 10;
