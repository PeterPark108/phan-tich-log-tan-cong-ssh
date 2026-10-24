-- Số sự kiện SSH theo giờ trong ngày (giờ của server)
SELECT CAST(strftime('%H', ts) AS INTEGER) AS gio, COUNT(*) AS so_su_kien
FROM logs WHERE program='sshd' GROUP BY gio ORDER BY gio;
