# MacifyWin

Biến giao diện và cử động **Windows 10/11** sang phong cách **macOS** chỉ với **1 lệnh duy nhất**, sử dụng hoàn toàn các công cụ và tài nguyên mã nguồn mở, **giữ nguyên icon ứng dụng gốc** và có script gỡ cài đặt sạch sẽ.

> [!NOTE]
> Dự án đang sử dụng tài nguyên thay thế mã nguồn mở (font **Inter**, con trỏ **Capitaine Cursors**), **không** chứa font, icon hay hình nền độc quyền của Apple.

---

## Ảnh minh họa

| Trước khi cài (Windows mặc định) | Sau khi cài (MacifyWin) |
| :---: | :---: |
| ![Before](docs/images/before-placeholder.png) | ![After](docs/images/after-placeholder.png) |

*(Bạn có thể chụp ảnh màn hình máy sau khi cài và lưu vào `docs/images/` để thay thế 2 ảnh mẫu trên.)*

---

## Tính năng chính

1. **Dock & Thanh Menu trên cùng (Seelen UI):** Dock nổi bo tròn căn giữa, phóng to icon khi rê chuột; thanh Menu Bar trên đỉnh màn hình với đồng hồ, Wi-Fi, pin, media và Control Center.
2. **Hiệu ứng mờ & Bo góc (Mica For Everyone / Windhawk):** Hiệu ứng Acrylic/Mica cho cửa sổ Win32 và Start Menu.
3. **Animation & Phím tắt (Windhawk + AutoHotkey v2):** Hiệu ứng thu nhỏ mượt, chuyển Virtual Desktop nhanh bằng `Ctrl + ← / →`, mở nhanh tìm kiếm bằng `Alt + Space`.
4. **Con trỏ, Font & Scrollbar:** Bộ con trỏ **Capitaine Cursors** (LGPL-3.0), font **Inter** (SIL OFL) kết hợp **MacType** làm mịn chữ, bật overlay scrollbar trên Windows 11.
5. **Giao diện bên trong ứng dụng:**
   - **Files App** thay thế Explorer với chế độ **Column View** giống Finder.
   - Tự động đồng bộ **Dark / Light Mode**.
   - Tự động cấu hình **VS Code** (không ghi đè thiết lập cũ) và hướng dẫn bật Mica titlebar cho **Chrome / Edge**.
6. **An toàn tuyệt đối:** Tự động tạo **System Restore Point** và sao lưu Registry vào `%LOCALAPPDATA%\MacifyWin\backup\` trước khi thay đổi.

---

## Cách cài đặt (1 lệnh duy nhất)

### Cách 1: Chạy trực tiếp file `.bat`
1. Tải repo bằng `git clone` hoặc **Download ZIP** rồi giải nén:
   ```powershell
   git clone https://github.com/your-username/MacifyWin.git
   cd MacifyWin
   ```
2. Nhấp đúp chuột vào file **`install.bat`** (hoặc chạy trong terminal). Script sẽ tự động xin quyền Administrator và thực hiện toàn bộ quá trình.
3. Sau khi hoàn tất, **Sign out** hoặc **Restart** máy để Font và MacType có hiệu lực đầy đủ.

### Cách 2: Chạy bằng PowerShell (tùy chọn Light Mode)
```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -Theme Light
```

---

## Cách gỡ cài đặt (Khôi phục Windows gốc)

Chạy file **`uninstall.bat`** với quyền Administrator:
- Tự động dừng các tiện ích giao diện (`Seelen UI`, `Windhawk`, `MicaForEveryone`, `AutoHotkey`).
- Khôi phục toàn bộ Registry gốc (con trỏ, theme, taskbar, animation) và `settings.json` của VS Code từ bản sao lưu.
- Hỏi tùy chọn gỡ các app đã cài qua `winget`.

---

## Tương thích phiên bản Windows

Xem chi tiết tại [docs/compatibility.md](docs/compatibility.md):
- **Windows 11 (22H2 / 23H2 / 24H2):** Hỗ trợ đầy đủ (khuyên dùng).
- **Windows 10 (21H2 / 22H2):** Hỗ trợ Seelen UI, Files App, MacType, AutoHotkey, Cursors; không có Mica/bo góc DWM gốc.

---

## Những phần KHÔNG thể giống macOS 100% & Cách khắc phục

| Hạn chế | Nguyên nhân kỹ thuật | Cách khắc phục gần nhất |
| :--- | :--- | :--- |
| **Nút Đỏ–Vàng–Xanh trên app tự vẽ UI** (Chrome, Edge, VS Code, Discord, Spotify) | Các app Electron/Chromium tự vẽ thanh tiêu đề và đặt nút ở góc phải. | Bật `Windows 11 Mica titlebar` trong `chrome://flags`; giữ `window.titleBarStyle: custom` trong VS Code. |
| **Global Menu Bar** (`File / Edit / View` tách lên thanh trên) | Windows gắn menu vào từng cửa sổ app thay vì tách lên đỉnh màn hình. | Dùng Top Bar của **Seelen UI** để hiển thị tên app active, tray, đồng hồ và Control Center. |
| **Font hệ thống toàn cục** | Windows khóa cứng `Segoe UI` trong các app UWP/WinUI hiện đại. | Cài font **Inter** cho các app hỗ trợ + **MacType** để làm nét chữ mịn, đậm giống macOS. |
| **Hiệu ứng Genie thu nhỏ cửa sổ** | Windows DWM không hỗ trợ uốn cong cửa sổ GPU cấp hệ thống. | Dùng mod animation của **Windhawk** để làm mượt chuyển động thu nhỏ/phóng to. |

---

## Lỗi thường gặp

Xem hướng dẫn xử lý chi tiết tại [docs/troubleshooting.md](docs/troubleshooting.md) và hướng dẫn chỉnh app tại [docs/app-theming-guide.md](docs/app-theming-guide.md).

## Giấy phép

Phát hành theo giấy phép [MIT License](LICENSE).
