# Khắc phục lỗi thường gặp (Troubleshooting)

## 1. Lỗi `winget` không tìm thấy hoặc lỗi nguồn (`msstore` / `winget`)
- Mở **Microsoft Store**, tìm và cập nhật **App Installer**.
- Hoặc mở PowerShell (Admin) và chạy: `winget source update`.

## 2. Đã chạy `install.bat` nhưng chưa thấy Font / MacType thay đổi
- Font mới và dịch vụ **MacType** cần **Sign out** (Đăng xuất) hoặc **Restart** máy để nạp vào các tiến trình hệ thống.
- Mở **MacType Wizard**, chọn **Service Mode** và trỏ tới profile `MacifyWin.ini`.

## 3. Nút Đỏ–Vàng–Xanh không hiện trên Chrome / VS Code / Discord
- Đây là giới hạn kiến trúc của các app tự vẽ thanh tiêu đề (Custom Titlebar / Electron / Chromium).
- Xem hướng dẫn tối ưu từng app tại [app-theming-guide.md](app-theming-guide.md).

## 4. Antivirus / Windows Defender cảnh báo Windhawk hoặc AutoHotkey
- `Windhawk` hoạt động bằng cơ chế tiêm code hợp lệ vào Explorer/Taskbar nên một số phần mềm diệt virus có thể cảnh báo nhầm (false positive). Nếu gặp cảnh báo, hãy thêm ngoại lệ cho thư mục `C:\Program Files\Windhawk`.

## 5. Muốn quay lại Windows gốc hoàn toàn
- Chạy `uninstall.bat` bằng quyền Administrator.
- Nếu cần khôi phục sâu hơn ở cấp hệ thống, mở **System Restore** (`rstrui.exe`) và chọn điểm khôi phục **"MacifyWin Pre-Install"** mà script đã tự tạo trước khi cài.

