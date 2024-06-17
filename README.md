# mobile_scanner_broken_set_scan_window

Showcasing broken mobile_scanner repo for github issue

## Getting Started

- Run `flutter run`

### Issue 1: `updateScanWindow` broken
- Attempt to scan something. You should see it in debug console
- Try to change the scanWindow by using the bottom right icon
- Now you can no longer scan anything

### Issue 2: Hot restart is not working
- Attempt to hot restart (i.e. shift+r or pressing green refresh icon in VSCode)
- See error: "Generic error: Called start() while already started!"
