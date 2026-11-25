# Hướng dẫn đồng bộ giao diện bên trong ứng dụng

Do nhiều ứng dụng hiện đại tự vẽ giao diện riêng (không dùng khung cửa sổ chuẩn của Windows), bạn có thể áp dụng thêm các thiết lập sau để đạt độ đồng bộ cao nhất:

## 1. Google Chrome / Microsoft Edge
- Mở `chrome://flags` (hoặc `edge://flags`).
- Tìm và bật (**Enabled**) các cờ sau:
  - `Windows 11 Mica titlebar` (giúp thanh tab có hiệu ứng mờ đồng bộ với hệ thống).
  - `Fluent scrollbars` (thanh cuộn mảnh, tự ẩn kiểu hiện đại).
- Khởi động lại trình duyệt.
- *(Tùy chọn)* Cài theme tối giản mã nguồn mở hoặc bật chế độ Dark/Light theo hệ thống trong `Settings -> Appearance`.

## 2. Visual Studio Code
- Script `install.bat` đã tự động sao lưu `settings.json` và gộp các thiết lập:
  - `window.titleBarStyle`: `custom`
  - `editor.fontFamily`: `'Inter', 'JetBrains Mono', Consolas, monospace`
  - Bật `smoothScrolling` và `cursorSmoothCaretAnimation`.
  - Cài extension `GitHub.github-vscode-theme` (mã nguồn mở).

## 3. Files App (Thay thế Finder)
- Đã cấu hình sẵn **Column View** (xem thư mục theo cột dọc giống Finder trên macOS) và giữ nguyên icon gốc của các ứng dụng.
- Để đặt Files App làm trình quản lý tệp mặc định thay Explorer, mở **Files App -> Settings -> Experimental -> Set Files as default file manager**.

