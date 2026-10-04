# Home Asset Manager
แอปจัดการทรัพย์สินภายในบ้าน

## 1. ภาพรวมโครงการ
Home Asset Manager เป็นแอป Flutter สำหรับจัดเก็บและจัดการข้อมูลทรัพย์สินภายในบ้านแบบ Offline-first โดยข้อมูลหลักถูกเก็บไว้ใน SQLite ผ่าน Drift

ผู้ใช้สามารถจัดการทรัพย์สิน หมวดหมู่ สถานที่ รายละเอียดการรับประกัน รายการโปรด ประวัติการซ่อม รูปภาพ และ QR Code ของทรัพย์สินได้จากภายในแอป

## 2. ฟังก์ชันหลัก
- เพิ่ม / แก้ไข / ลบ / ดูรายละเอียดทรัพย์สิน
- ค้นหาทรัพย์สิน
- Filter และ Sort
- จัดการหมวดหมู่
- จัดการสถานที่
- บันทึกราคาซื้อและวันที่ซื้อ
- บันทึกวันหมดประกันและแสดงสถานะประกัน
- แจ้งเตือนเมื่อการรับประกันใกล้หมด
- รายการโปรด (Favorite)
- เพิ่มรูปภาพทรัพย์สิน
- สร้าง QR Code ประจำทรัพย์สิน
- สแกน QR Code เพื่อเปิดรายละเอียดทรัพย์สิน
- บันทึกประวัติการซ่อมและค่าใช้จ่าย
- สำรองและกู้คืนข้อมูล
- Dashboard / สถิติ
- รองรับ Light / Dark theme ตามการตั้งค่าของระบบ/แอป

## 3. Technology
- Flutter / Dart
- Material 3
- Provider + ChangeNotifier
- Drift + SQLite
- Repository Pattern
- Layered Architecture
- image_picker
- mobile_scanner
- qr_flutter
- flutter_local_notifications
- file_picker
- share_plus
- pdf
- printing
- gal
- path_provider

## 4. Architecture

```text
┌──────────────────────────────┐
│ Screen / Widget              │
│ Flutter + Material 3         │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Provider / ChangeNotifier    │
│ State + UI business flow     │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Repository                   │
│ Data access abstraction      │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ DAO                          │
│ Drift database operations    │
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│ Drift / SQLite               │
│ Local persistent storage     │
└──────────────────────────────┘
```

## 5. โครงสร้างข้อมูลหลัก

### Categories
เก็บหมวดหมู่ของทรัพย์สิน

### Locations
เก็บสถานที่ภายในบ้าน

### Assets
เก็บข้อมูลทรัพย์สิน เช่น ชื่อ รายละเอียด หมวดหมู่ สถานที่ ราคา วันที่ซื้อ วันหมดประกัน สภาพ Serial Number รูปภาพ Favorite และ timestamps

### MaintenanceRecords
เก็บประวัติการซ่อมของทรัพย์สิน เช่น วันที่ ประเภท รายละเอียด ค่าใช้จ่าย และหมายเหตุ

## 6. การติดตั้งและรัน

ต้องติดตั้ง Flutter SDK และ Android development environment ให้พร้อมก่อน

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## 7. Build Release APK

```bash
flutter build apk --release
```

ไฟล์ APK:

```text
build/app/outputs/flutter-apk/app-release.apk
```

## 8. การทดสอบ
ผลการตรวจสอบรอบสุดท้ายของโครงการ:
- `flutter analyze` → ผ่าน ไม่มี issues
- `flutter test` → ผ่าน
- Release APK → Build สำเร็จ
- Release APK ขนาดประมาณ 79.3 MB
- ทดสอบการใช้งานบน Android เครื่องจริงแล้ว

## 9. ข้อมูลภายในเครื่อง
แอปใช้ SQLite ภายในเครื่อง จึงสามารถใช้งานโดยไม่ต้องมี Backend หรือ Cloud Server

ฐานข้อมูลใช้ชื่อ:

```text
home_asset_manager.sqlite
```

## 10. Backup / Restore
ระบบ Backup สามารถเก็บข้อมูลหมวดหมู่ สถานที่ ทรัพย์สิน และประวัติการซ่อมในไฟล์สำรองได้

หมายเหตุ: path ของรูปภาพถูกเก็บไว้ในข้อมูลสำรอง แต่ไฟล์รูปภาพไม่ได้ถูกฝังเป็น binary ใน JSON backup ดังนั้นการย้าย backup ข้ามเครื่องอาจทำให้รูปภาพเดิมไม่สามารถเปิดได้หากไฟล์ต้นฉบับไม่ได้ถูกย้ายไปด้วย

## 11. ข้อจำกัด
- เป็นระบบ Local-first จึงไม่มีการ Sync ข้อมูลข้ามอุปกรณ์
- ข้อมูลอยู่ในเครื่องเป็นหลัก
- Backup JSON ไม่ได้ฝังไฟล์รูปภาพเป็น binary
- Notification ขึ้นอยู่กับ permission และการตั้งค่าของ Android
- การลบข้อมูลเป็นการดำเนินการที่ควรตรวจสอบก่อนยืนยัน

## 12. License
โครงการนี้จัดทำเพื่อการศึกษาในรายวิชา Mobile Application Development
