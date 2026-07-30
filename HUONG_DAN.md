# HAOTOOL Modular V2.3.4

Bộ mã nguồn này chia HAOTOOL thành 18 phần để dễ tìm, sửa và kiểm tra. Các file trong `src/` là những mảnh mã nguồn có chung phạm vi biến; không chạy từng file riêng lẻ và không đổi thứ tự trong `manifest.txt` nếu chưa kiểm tra phụ thuộc.

## Cách sửa và dựng lại

1. Sửa file tương ứng trong thư mục `src/`.
2. Nhấp phải `build.ps1` và chạy bằng PowerShell, hoặc mở PowerShell tại thư mục này rồi chạy:

   `powershell -ExecutionPolicy Bypass -File .\build.ps1`

3. Bản hoàn chỉnh được tạo tại `dist/main.lua`.
4. Dùng `dist/main.lua` trong executor như bản `main.lua` cũ.

## Cấu trúc chính

- `src/00–03`: khởi động, Fluent, cấu hình và dữ liệu game.
- `src/04–07`: di chuyển, chiến đấu, tìm mục tiêu và các tính năng độc lập.
- `src/08–10`: ESP và toàn bộ vòng lặp nền.
- `src/11–17`: khung giao diện và từng nhóm tab.
- `vendor/fluent.lua`: Fluent được lưu cục bộ, không phụ thuộc mạng khi bản đóng gói chạy.
- `runtime/launcher.lua`: lưu bản tự nạp và chạy payload.
- `manifest.txt`: thứ tự ghép module.
- `dev_loader.lua`: chế độ phát triển, chỉ dùng nếu executor hỗ trợ `readfile` và thư mục đã nằm trong workspace của executor.

## Lưu ý tối ưu

Tách file không tự làm game chạy nhanh hơn. Bản dựng vẫn ghép thành một chunk Luau để các biến cục bộ hoạt động đúng và tránh chi phí `require` lúc chạy. Hệ thống token hiện tại bảo đảm khi chạy lại script, các vòng lặp cũ dừng trước khi vòng lặp mới được tạo.
