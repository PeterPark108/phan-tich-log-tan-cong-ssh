"""Tra vị trí IP bằng cơ sở dữ liệu offline DB-IP Lite (https://db-ip.com, giấy phép CC BY 4.0).
LƯU Ý: đây là vị trí HIỆN TẠI (bản 2026-10) của IP, KHÔNG phải vị trí lúc tấn công (log cũ) -> chỉ để tham khảo.
Kết quả lưu ở data/ip_geo.csv (notebook chỉ đọc file này, không cần chạy lại script)."""
import re, gzip, csv, bisect, ipaddress, urllib.request
from pathlib import Path
import pandas as pd
VER = '2026-10'
def get(kind):
    p = Path(f'data/dbip-{kind}.csv.gz')
    if not p.exists():
        urllib.request.urlretrieve(f'https://download.db-ip.com/free/dbip-{kind}-lite-{VER}.csv.gz', p)
    starts, rows = [], []
    with gzip.open(p, 'rt', encoding='utf-8') as f:
        for r in csv.reader(f):
            if ':' in r[0]: continue
            starts.append(int(ipaddress.IPv4Address(r[0]))); rows.append(r)
    return starts, rows
def find(db, ip):
    s, rows = db; n = int(ipaddress.IPv4Address(ip)); i = bisect.bisect_right(s, n) - 1
    r = rows[i]; return r if i >= 0 and n <= int(ipaddress.IPv4Address(r[1])) else None
ips = sorted(set(re.findall(r'\b\d{1,3}(?:\.\d{1,3}){3}\b', gzip.open('data/auth.log.gz','rt',errors='replace').read())))
city, asn = get('city'), get('asn')
out = []
for ip in ips:
    c, a = find(city, ip), find(asn, ip)
    out.append(dict(ip=ip, continent=c and c[2], country_code=c and c[3], region=c and c[4], city=c and c[5],
                    lat=c and float(c[6]), lon=c and float(c[7]), asn=a and int(a[2]), as_org=a and a[3], geo_source=f'DB-IP Lite {VER} (hiện tại)'))
pd.DataFrame(out).to_csv('data/ip_geo.csv', index=False, encoding='utf-8-sig'); print('Đã tra', len(out), 'IP')
