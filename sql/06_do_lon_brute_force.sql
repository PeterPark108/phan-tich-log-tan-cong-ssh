-- Phân nhóm IP theo độ lớn brute-force (số lần thử user không tồn tại)
WITH per_ip AS (
  SELECT ip, COUNT(*) AS n FROM logs WHERE event_type='invalid_user' GROUP BY ip)
SELECT CASE WHEN n=1 THEN '1' WHEN n<=10 THEN '2-10' WHEN n<=100 THEN '11-100'
            WHEN n<=1000 THEN '101-1000' ELSE '>1000' END AS nhom,
       COUNT(*) AS so_ip, SUM(n) AS tong_lan_thu
FROM per_ip GROUP BY nhom ORDER BY MIN(n);
