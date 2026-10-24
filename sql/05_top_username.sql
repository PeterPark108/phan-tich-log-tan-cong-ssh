-- Top 15 username không tồn tại bị kẻ tấn công thử
SELECT username, COUNT(*) AS so_lan_thu, COUNT(DISTINCT ip) AS so_ip
FROM logs WHERE event_type='invalid_user'
GROUP BY username ORDER BY so_lan_thu DESC LIMIT 15;
