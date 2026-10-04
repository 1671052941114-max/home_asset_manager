# Presentation — Home Asset Manager (ประมาณ 10 นาที)

## Slide 1 — Title (30 วินาที)
**Home Asset Manager**
แอปจัดการทรัพย์สินภายในบ้าน

พูด:
“โครงการนี้เป็นแอป Flutter สำหรับช่วยจัดเก็บและจัดการทรัพย์สินภายในบ้าน โดยเน้นการใช้งานแบบ Offline-first และเก็บข้อมูลด้วย SQLite”

## Slide 2 — Problem / Objective (45 วินาที)
ปัญหา:
- จำไม่ได้ว่าของอยู่ที่ไหน
- ข้อมูลราคา/วันซื้อกระจัดกระจาย
- ตรวจประกันและประวัติซ่อมยาก

เป้าหมาย:
- รวมข้อมูลทรัพย์สินไว้ในแอปเดียว
- ค้นหาและจัดการได้ง่าย
- มีข้อมูลประกันและการซ่อม
- ใช้งานได้โดยไม่ต้องมี server

## Slide 3 — Main Features (1 นาที)
แสดง:
- CRUD
- Search / Filter / Sort
- Category / Location
- Favorite
- Warranty
- Maintenance
- QR Code
- Notification
- Backup / Restore
- Statistics

## Slide 4 — UI Demo (1 นาที)
แสดง:
Home → Asset List → Asset Detail → Add/Edit

## Slide 5 — QR / Maintenance / Warranty (1 นาที)
แสดง:
- QR Generate
- QR Scan
- Maintenance
- Warranty status

## Slide 6 — Architecture (1 นาที)
```text
Screen
  ↓
Provider
  ↓
Repository
  ↓
DAO
  ↓
Drift
  ↓
SQLite
```

พูด:
“ผมแยก UI, state, data access และ database ออกจากกัน เพื่อให้แก้ไขและทดสอบแต่ละส่วนได้ง่ายขึ้น”

## Slide 7 — Database (1 นาที)
Tables:
- Categories
- Locations
- Assets
- MaintenanceRecords

พูดถึง relation ระหว่าง Asset กับ Category / Location และ Maintenance กับ Asset

## Slide 8 — Security (1 นาที)
พูดถึง:
- validation
- QR validation
- typed Drift queries
- backup validation
- confirmation ก่อนลบ
- error handling
- notification permission

## Slide 9 — Testing / Problems (1 นาที)
ผลล่าสุด:
- `flutter analyze` → 0 issues
- `flutter test` → ผ่าน
- Release APK → build สำเร็จ
- ทดสอบบน Android เครื่องจริง → ผ่าน

ปัญหาที่พบ:
- ProviderNotFoundException
- Drift migration
- package dependency conflict
- dialog controller lifecycle
- QR/PDF API

## Slide 10 — Conclusion / Q&A (45 วินาที)
พูด:
“โครงการนี้ช่วยให้การจัดการทรัพย์สินภายในบ้านเป็นระบบมากขึ้น และแสดงการประยุกต์ใช้ Flutter, Provider, Repository Pattern และ Drift/SQLite ในแอปจริง ขอบคุณครับ”

### Demo Flow ที่แนะนำ
1. เปิด Home
2. เปิดรายการทรัพย์สิน
3. เปิดรายละเอียด
4. แสดง Favorite
5. แสดง Warranty
6. เพิ่ม Maintenance
7. เปิด QR
8. สแกน QR
9. กลับ Home / Statistics
10. จบด้วย Architecture และ Testing
