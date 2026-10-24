-- Top 10 IP có nhiều sự kiện tấn công SSH nhất
SELECT ip, COUNT(*) AS so_su_kien,
       COUNT(DISTINCT date(ts)) AS so_ngay_hoat_dong,
       MIN(ts) AS lan_dau, MAX(ts) AS lan_cuoi
FROM logs WHERE ip IS NOT NULL AND program='sshd'
GROUP BY ip ORDER BY so_su_kien DESC LIMIT 10;
