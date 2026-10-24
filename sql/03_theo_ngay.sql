-- Số sự kiện SSH theo ngày
SELECT date(ts) AS ngay, COUNT(*) AS so_su_kien, COUNT(DISTINCT ip) AS so_ip
FROM logs WHERE program='sshd' GROUP BY ngay ORDER BY ngay;
