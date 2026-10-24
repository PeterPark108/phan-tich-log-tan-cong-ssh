# 🕷️ Hướng dẫn dựng dashboard Power BI – PeterPark SSH Attack Log

Máy anh **đã có Power BI Desktop** (bản Microsoft Store 2.159). Mở bằng Start → gõ **Power BI Desktop**.

Dữ liệu nằm trong thư mục `powerbi\` (do notebook mục 6 tạo ra, UTF-8):

| File | Vai trò | Số dòng | Khoá |
|---|---|---|---|
| `fact_su_kien.csv` | Bảng sự kiện (fact) – mỗi dòng 1 sự kiện sshd | 85.246 | `event_id` |
| `fact_dot_tan_cong.csv` | Mỗi đợt tấn công (session, ngắt > 30 phút) | 3.037 | `session_id` |
| `dim_ip.csv` | Mỗi IP: quốc gia, thành phố, lat/lon, ASN, tổng, phân loại | 1.843 | `ip` |
| `dim_ngay.csv` | Lịch 30/11 → 31/12 | 32 | `ngay` |
| `dim_username.csv` | Mỗi username bị thử + nhóm | 543 | `username` |

> Năm 2000 trong ngày tháng là **năm giả định** (log không ghi năm). Giờ là **giờ server**. Vị trí IP là vị trí **hiện tại** theo DB-IP Lite (2026-10), không phải lúc tấn công.

---
## Bước 1 – Nạp dữ liệu
1. **Home → Get data → Text/CSV** → chọn `fact_su_kien.csv` → *File Origin*: **65001: Unicode (UTF-8)** → **Transform Data**.
2. Lặp lại cho 4 file còn lại (hoặc **Get data → Folder** rồi chọn từng file).
3. Trong Power Query kiểm tra kiểu dữ liệu:
   - `timestamp`, `lan_dau`, `lan_cuoi`, `bat_dau`, `ket_thuc` → **Date/Time**
   - `ngay` (ở mọi bảng) → **Date**
   - `gio`, `so_*`, `asn` → **Whole Number**; `lat`, `lon`, `thoi_luong_phut`, `toc_do_moi_phut`, `gap_trung_vi_s` → **Decimal Number**
   - Nếu ngày bị đọc sai (do máy để định dạng Việt Nam): chuột phải cột → **Change Type → Using Locale… → Date, English (United States)**.
4. **Close & Apply**.

## Bước 2 – Áp theme Spider-Man
**View → Themes → Browse for themes** → chọn `powerbi\peterpark_theme.json` (đỏ `#C8102E`, xanh `#1F3A93`).

## Bước 3 – Quan hệ (Model view)
Kéo thả để tạo quan hệ **Many-to-one (*:1), Single direction** từ fact sang dim:

| Từ (nhiều) | Đến (một) |
|---|---|
| `fact_su_kien[ip]` | `dim_ip[ip]` |
| `fact_su_kien[ngay]` | `dim_ngay[ngay]` |
| `fact_su_kien[username]` | `dim_username[username]` |
| `fact_dot_tan_cong[ip]` | `dim_ip[ip]` |
| `fact_dot_tan_cong[ngay]` | `dim_ngay[ngay]` |

Sau đó: chọn bảng `dim_ngay` → **Table tools → Mark as date table** → cột `ngay`.
Trong `dim_ngay`, chọn cột `ngay_thang` → **Sort by column → ngay**.
Trong `dim_ip`: cột `country_code` → *Data category* = **Country/Region**; `lat` = **Latitude**; `lon` = **Longitude**; `city` = **City**.

## Bước 4 – Tạo bảng Measure & dán DAX
**Home → Enter data** → đặt tên bảng `_Measures` → Load. Chọn bảng đó → **New measure**, dán từng dòng:

```DAX
Tổng sự kiện = COUNTROWS ( fact_su_kien )
Số IP tấn công = DISTINCTCOUNT ( fact_su_kien[ip] )
Số đợt tấn công = COUNTROWS ( fact_dot_tan_cong )
Số quốc gia = DISTINCTCOUNT ( dim_ip[country_code] )
Lần thử username sai = CALCULATE ( [Tổng sự kiện], fact_su_kien[event_type] = "invalid_user" )
Lần tấn công root = CALCULATE ( [Tổng sự kiện], fact_su_kien[event_type] = "too_many_auth_failures" )
Số username khác nhau = CALCULATE ( DISTINCTCOUNT ( fact_su_kien[username] ), fact_su_kien[event_type] = "invalid_user" )
Sự kiện / IP = DIVIDE ( [Tổng sự kiện], [Số IP tấn công] )
Sự kiện TB / ngày = AVERAGEX ( VALUES ( dim_ngay[ngay] ), [Tổng sự kiện] )
Ngày cao điểm = MAXX ( TOPN ( 1, VALUES ( dim_ngay[ngay_thang] ), [Tổng sự kiện] ), dim_ngay[ngay_thang] )
Sự kiện ngày cao điểm = MAXX ( VALUES ( dim_ngay[ngay] ), [Tổng sự kiện] )
IP mạnh nhất = MAXX ( TOPN ( 1, VALUES ( dim_ip[ip] ), [Tổng sự kiện] ), dim_ip[ip] )
% Sự kiện = DIVIDE ( [Tổng sự kiện], CALCULATE ( [Tổng sự kiện], ALL ( fact_su_kien ) ) )
% Top 10 IP =
VAR top10 = TOPN ( 10, ALL ( dim_ip[ip] ), [Tổng sự kiện] )
RETURN DIVIDE ( CALCULATE ( [Tổng sự kiện], top10 ), CALCULATE ( [Tổng sự kiện], ALL ( dim_ip ) ) )
Pareto % cộng dồn =
VAR cur = [Tổng sự kiện]
VAR tong = CALCULATE ( [Tổng sự kiện], ALL ( dim_ip ) )
VAR cong_don = SUMX ( FILTER ( ALL ( dim_ip ), dim_ip[so_su_kien] >= MAX ( dim_ip[so_su_kien] ) ), dim_ip[so_su_kien] )
RETURN IF ( NOT ISBLANK ( cur ), DIVIDE ( cong_don, tong ) )
IP quay lại (≥2 ngày) = CALCULATE ( DISTINCTCOUNT ( dim_ip[ip] ), dim_ip[so_ngay] >= 2 )
% IP chỉ 1 ngày = DIVIDE ( CALCULATE ( COUNTROWS ( dim_ip ), dim_ip[so_ngay] = 1 ), COUNTROWS ( dim_ip ) )
Thời lượng đợt TB (phút) = AVERAGE ( fact_dot_tan_cong[thoi_luong_phut] )
Tốc độ đỉnh (sự kiện/phút) = MAX ( fact_dot_tan_cong[toc_do_moi_phut] )
Đợt bot tốc độ cao = CALCULATE ( [Số đợt tấn công], fact_dot_tan_cong[hanh_vi] = "Bot tốc độ cao (≤5s)" )
% Sự kiện do bot nhanh = DIVIDE ( CALCULATE ( SUM ( fact_dot_tan_cong[so_su_kien] ), fact_dot_tan_cong[hanh_vi] = "Bot tốc độ cao (≤5s)" ), SUM ( fact_dot_tan_cong[so_su_kien] ) )
```
Định dạng: các measure `%` → **Measure tools → Format = Percentage, 1 chữ số thập phân**; số lớn → *Whole number, dấu phân cách hàng nghìn*.

> Đối chiếu: sau khi dựng xong, card **Tổng sự kiện** phải ra **85.246**, **Số IP tấn công** ~**1.843** (chênh nhẹ nếu IP suy ra từ pid), **Số đợt** **3.037** – khớp notebook.

---
## Bước 5 – Bố cục 3 trang (canvas 16:9, 1280×720)

### Trang 1 – Tổng quan
```
┌───────────────────────────────────────────────────────────────┐
│ 🕷️ PeterPark · SSH Attack Dashboard        [Slicer: ngày ▭▭▭] │  ← Text box xanh #1F3A93 + Slicer "Between" dim_ngay[ngay]
├─────────┬─────────┬─────────┬─────────┬─────────┬─────────────┤
│Tổng sự  │Số IP    │Số đợt   │Lần thử  │Lần root │% Top 10 IP  │  ← 6 Card (số đỏ)
│kiện     │         │         │user sai │         │             │
├─────────┴─────────┴─────────┴─────┬───┴─────────┴─────────────┤
│ Line/Area chart: Tổng sự kiện     │ Donut: % Sự kiện theo     │
│ theo dim_ngay[ngay_thang]         │ fact_su_kien[event_type]  │
│ (bật Analytics → Max line đỏ)     │                           │
├───────────────────────────────────┼───────────────────────────┤
│ Matrix heatmap: Rows = ngay_thang,│ Column chart: Tổng sự kiện│
│ Columns = gio, Values = Tổng sự   │ theo fact_su_kien[gio]    │
│ kiện → Conditional formatting →   │                           │
│ Background color: trắng → đỏ      │                           │
└───────────────────────────────────┴───────────────────────────┘
```

### Trang 2 – IP & địa lý
```
┌───────────────────────────────────┬───────────────────────────┐
│ Map (hoặc Azure Map):             │ Bar: Top 10 quốc gia       │
│ Latitude = dim_ip[lat],           │ (country_code, Tổng sự    │
│ Longitude = dim_ip[lon],          │ kiện, Filter Top N = 10)  │
│ Bubble size = Tổng sự kiện,       ├───────────────────────────┤
│ Tooltip = ip, city, as_org        │ Bar: Top 10 ASN (as_org)  │
├───────────────────────────────────┼───────────────────────────┤
│ Table Top 15 IP: ip, country_code,│ Line+Column (Pareto):     │
│ as_org, so_ngay, so_dot, Tổng sự  │ Axis = dim_ip[ip] sort    │
│ kiện, phan_loai (data bars đỏ)    │ giảm dần, Column = Tổng sự│
│                                   │ kiện, Line = Pareto %      │
├───────────────────────────────────┴───────────────────────────┤
│ Slicer: dim_ip[phan_loai] · dim_ip[continent] · Card: IP quay │
│ lại (≥2 ngày), % IP chỉ 1 ngày, Số quốc gia                   │
└───────────────────────────────────────────────────────────────┘
```
*Nếu visual Map bị tắt:* **File → Options → Security → Map and Filled Map visuals** → bật. Ghi chú nhỏ dưới bản đồ: "Vị trí hiện tại theo DB-IP Lite, không phải lúc tấn công".

### Trang 3 – Tài khoản & hành vi
```
┌─────────────┬─────────────┬─────────────┬─────────────────────┐
│Số username  │Đợt bot tốc  │% Sự kiện do │Tốc độ đỉnh          │  ← 4 Card
│khác nhau    │độ cao       │bot nhanh    │(sự kiện/phút)       │
├─────────────┴─────────────┼─────────────┴─────────────────────┤
│ Treemap: dim_username     │ Bar: Top 15 username (Lần thử     │
│ [nhom_user] → username,   │ username sai, Top N = 15)         │
│ Values = Lần thử username │                                   │
│ sai                       │                                   │
├───────────────────────────┼───────────────────────────────────┤
│ Scatter: fact_dot_tan_cong│ Stacked column: Lần thử username  │
│ X = gap_trung_vi_s (log), │ sai & Lần tấn công root theo      │
│ Y = so_su_kien (log),     │ dim_ngay[ngay_thang]              │
│ Legend = hanh_vi,         │ (root đỏ, username xanh)          │
│ Values = session_id       │                                   │
├───────────────────────────┴───────────────────────────────────┤
│ Table đợt dài nhất: session_id, bat_dau, thoi_luong_phut,     │
│ so_su_kien, toc_do_moi_phut, hanh_vi (sort so_su_kien giảm)   │
└───────────────────────────────────────────────────────────────┘
```
Scatter: **Format → X axis / Y axis → Scale type = Log**.

## Bước 6 – Hoàn thiện
- **View → Sync slicers**: cho slicer ngày áp dụng cả 3 trang.
- Thêm logo PeterPark (Insert → Image) góc trái mỗi trang.
- Thêm nút điều hướng: **Insert → Buttons → Navigator → Page navigator**.
- Lưu: **File → Save as** `PeterPark_SSH_Dashboard.pbix` trong thư mục dự án; chụp màn hình từng trang để đưa lên website/GitHub.

## Nguồn & giấy phép
- Log: SecRepo.com – Mike Sconzo, CC BY 4.0.
- Vị trí IP: [DB-IP Lite](https://db-ip.com) (IP Geolocation by DB-IP), CC BY 4.0 – cần ghi nguồn trên dashboard.
