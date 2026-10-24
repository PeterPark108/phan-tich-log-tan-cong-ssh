-- Top 10 dải mạng /24 (cột subnet24 được tính sẵn khi nạp dữ liệu)
SELECT subnet24, COUNT(*) AS so_su_kien, COUNT(DISTINCT ip) AS so_ip
FROM logs WHERE subnet24 IS NOT NULL AND program='sshd'
GROUP BY subnet24 ORDER BY so_su_kien DESC LIMIT 10;
