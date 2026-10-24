-- Tổng quan: số dòng log, số sự kiện theo loại
SELECT event_type, COUNT(*) AS so_su_kien
FROM logs GROUP BY event_type ORDER BY so_su_kien DESC;
