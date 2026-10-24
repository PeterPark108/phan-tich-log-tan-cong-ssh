"""Tải lại bộ dữ liệu gốc auth.log từ SecRepo (CC BY 4.0, tác giả Mike Sconzo)."""
import gzip, shutil, urllib.request, pathlib
URL = "https://www.secrepo.com/auth.log/auth.log.gz"
out = pathlib.Path(__file__).parent / "data"; out.mkdir(exist_ok=True)
gz = out / "auth.log.gz"
urllib.request.urlretrieve(URL, gz)
with gzip.open(gz, "rb") as f, open(out / "auth.log", "wb") as g:
    shutil.copyfileobj(f, g)
print("Đã tải:", out / "auth.log")
