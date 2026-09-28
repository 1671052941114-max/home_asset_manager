# Home Asset Manager

แอปพลิเคชันสำหรับจัดการทรัพย์สินภายในบ้าน พัฒนาด้วย Flutter และ Dart โดยใช้ Drift และ SQLite สำหรับจัดเก็บข้อมูลภายในเครื่อง

## 1. รายละเอียดโครงการ

**ชื่อโครงการ:** Home Asset Manager  
**ชื่อภาษาไทย:** แอปจัดการทรัพย์สินภายในบ้าน  
**Version:** 1.0.0

Home Asset Manager ช่วยให้ผู้ใช้บันทึกและจัดการทรัพย์สินภายในบ้าน เช่น โทรศัพท์ คอมพิวเตอร์ เครื่องใช้ไฟฟ้า และทรัพย์สินประเภทต่าง ๆ ได้อย่างเป็นระบบ โดยรองรับการเพิ่ม แก้ไข ลบ ค้นหา กรอง เรียงลำดับ ดูรายละเอียด จัดการหมวดหมู่และสถานที่ รวมถึงติดตามข้อมูลประกัน

ระบบเป็น Local-first และใช้ SQLite ผ่าน Drift จึงไม่จำเป็นต้องมี Backend หรือระบบ Login สำหรับการใช้งานเวอร์ชันนี้

## 2. วัตถุประสงค์

- จัดเก็บข้อมูลทรัพย์สินภายในบ้านอย่างเป็นระบบ
- รองรับ CRUD สำหรับทรัพย์สิน
- ค้นหา กรอง และเรียงลำดับทรัพย์สิน
- จัดการหมวดหมู่และสถานที่
- บันทึกรูปภาพจาก Camera และ Gallery
- ติดตามวันหมดประกัน
- แสดงจำนวนและมูลค่ารวมของทรัพย์สิน
- เก็บข้อมูลไว้ใน SQLite ภายในอุปกรณ์

## 3. Features

### Asset Management
- เพิ่ม แก้ไข ลบ และดูรายละเอียดทรัพย์สิน
- ชื่อ รายละเอียด หมวดหมู่ สถานที่ ราคา วันที่ซื้อ วันหมดประกัน สภาพ Serial Number และรูปภาพ
- Validation ข้อมูลก่อนบันทึก

### Search / Filter / Sort
- ค้นหาจากชื่อ Serial Number และรายละเอียด
- Filter ตามหมวดหมู่ สถานที่ สภาพ และสถานะประกัน
- Sort ตามชื่อ ราคา และวันที่ซื้อ

### Image
- เลือกรูปจาก Gallery
- ถ่ายรูปจาก Camera
- เก็บไฟล์รูปไว้ในพื้นที่เอกสารของแอป
- แสดงรูปใน Home, Assets, Statistics และ Detail

### Category / Location
- เพิ่ม แก้ไข และลบ
- ป้องกันชื่อซ้ำ
- ป้องกันการลบข้อมูลที่ยังถูกใช้งาน

### Warranty
- ยังไม่ระบุ
- ยังมีประกัน
- ใกล้หมดประกัน
- หมดประกันแล้ว

สถานะ “ใกล้หมดประกัน” ใช้ช่วงเวลาภายใน 30 วัน

### Statistics
- จำนวนทรัพย์สิน
- มูลค่ารวม
- จำนวนประกันแต่ละสถานะ
- รายการทรัพย์สินล่าสุด

### Settings
- Theme ตามระบบ
- Theme สว่าง
- Theme มืด
- Category Management
- Location Management
- ข้อมูลแอปและ Technology Stack

## 4. Technology Stack

| Technology | Usage |
|---|---|
| Flutter | Mobile App Framework |
| Dart | Programming Language |
| Material 3 | UI / Design System |
| Provider | State Management |
| ChangeNotifier | State Notification |
| Drift | SQLite Database Abstraction |
| SQLite | Local Database |
| image_picker | Camera / Gallery |
| flutter_test | Automated Testing |
| Git | Version Control |
| GitHub | Source Code Repository |

## 5. Architecture

ใช้ Layered Architecture ร่วมกับ Repository Pattern

```text
Screen / Widget
      ↓
Provider / ChangeNotifier
      ↓
Repository
      ↓
Drift / DAO
      ↓
SQLite
```

หน้าจอไม่เข้าถึง Database โดยตรง แต่ส่งข้อมูลผ่าน Provider และ Repository ก่อนถึง DAO/Drift

## 6. Project Structure

```text
lib/
├── core/
│   ├── database/
│   ├── theme/
│   └── utils/
├── data/
│   └── database/
│       ├── daos/
│       └── tables/
├── providers/
├── repositories/
├── screens/
│   ├── assets/
│   ├── categories/
│   ├── home/
│   ├── locations/
│   ├── settings/
│   └── statistics/
├── widgets/
└── main.dart

test/
└── widget_test.dart
```

## 7. Database

ใช้ **Drift + SQLite**

### Tables

**Categories**
- id
- name
- createdAt

**Locations**
- id
- name
- createdAt

**Assets**
- id
- name
- description
- categoryId
- locationId
- purchasePrice
- purchaseDate
- warrantyEndDate
- condition
- serialNumber
- imagePath
- createdAt
- updatedAt

Database file:

```text
home_asset_manager.sqlite
```

## 8. Image Storage

รูปภาพจะถูกคัดลอกไปยังพื้นที่เอกสารของแอปใน:

```text
asset_images/
```

และเก็บ Path ของไฟล์ไว้ใน SQLite

ตัวอย่างชื่อไฟล์:

```text
asset_<timestamp>.jpg
```

## 9. Validation และ Error Handling

ระบบตรวจสอบข้อมูล เช่น

- ชื่อทรัพย์สินต้องไม่ว่าง
- ราคาต้องไม่ติดลบ
- ต้องเลือกหมวดหมู่
- ต้องเลือกสถานที่
- วันหมดประกันต้องไม่ก่อนวันที่ซื้อ
- ป้องกัน Category ซ้ำ
- ป้องกัน Location ซ้ำ
- ป้องกันการลบ Category/Location ที่ถูกใช้งาน

รองรับสถานะ Loading, Empty, Error และ Refresh ในหน้าที่เกี่ยวข้อง

## 10. State Management

ใช้ Provider + ChangeNotifier

```text
AssetProvider
CategoryProvider
LocationProvider
ThemeProvider
```

## 11. การติดตั้ง

ต้องมี Flutter SDK และเครื่องมือสำหรับ Platform ที่ต้องการใช้งาน

ตรวจสอบ environment:

```bash
flutter doctor
```

Clone:

```bash
git clone https://github.com/1671052941114-max/home_asset_manager.git
cd home_asset_manager
```

ติดตั้ง package:

```bash
flutter pub get
```

รัน:

```bash
flutter run
```

## 12. Development Commands

ตรวจสอบโค้ด:

```bash
flutter analyze
```

ทดสอบ:

```bash
flutter test
```

หากมีการแก้ Drift Table หรือ DAO:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 13. Release APK

สร้าง Release APK:

```bash
flutter build apk --release
```

ไฟล์:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Release APK ของเวอร์ชันนี้ Build สำเร็จและมีขนาดประมาณ **56.5 MB**

## 14. Testing

ผ่านการตรวจสอบ:

```text
flutter analyze       PASS
flutter test          PASS
flutter build apk     PASS
Manual Functional QA  PASS
```

Manual QA ครอบคลุม:

- CRUD
- Search
- Filter
- Sort
- Image Camera / Gallery
- Category / Location
- Warranty
- Statistics
- Theme
- Validation
- Duplicate Data
- Persistence หลังปิดและเปิดแอป

## 15. Secure Coding

- ไม่มี Password หรือ Authentication ในระบบ
- ไม่มี API Key หรือ Secret Key ที่จำเป็นต้องฝังใน Source Code
- ข้อมูลหลักจัดเก็บใน Local SQLite
- ตรวจสอบ Input ก่อนบันทึก
- ป้องกันข้อมูล Category และ Location ซ้ำ
- ป้องกันการลบข้อมูลที่ยังมีการอ้างอิง
- แยก UI, State, Repository และ Database Access
- ไม่ Commit Build และ Cache ที่ไม่จำเป็นผ่าน `.gitignore`

## 16. Limitations

- ข้อมูลเป็น Local ภายในอุปกรณ์
- ไม่มี Cloud Sync
- ไม่มี Login / User Account
- ไม่มี Cloud Backup
- Search / Filter / Sort ทำงานกับข้อมูลที่โหลดใน Provider เหมาะกับ Dataset ขนาดเล็กถึงปานกลาง
- Theme ที่เลือกยังไม่ถูกบันทึกเป็นค่าถาวรหลังปิดแอป
- ไม่มี Push Notification สำหรับ Warranty

## 17. Future Improvements

- Backup / Restore Database
- Export CSV / PDF
- Cloud Sync
- Authentication
- Warranty Notification
- Dashboard Charts
- รองรับ Dataset ขนาดใหญ่ด้วย Database Query / Pagination
- บันทึก Theme Preference แบบถาวร

## 18. Repository

https://github.com/1671052941114-max/home_asset_manager

## 19. สรุป

Home Asset Manager เป็นแอป Flutter สำหรับจัดการทรัพย์สินภายในบ้าน โดยใช้ Flutter/Dart, Material 3, Provider, ChangeNotifier, Repository Pattern, Drift และ SQLite

ระบบรองรับ CRUD, Search, Filter, Sort, Category, Location, Image, Warranty Tracking, Statistics และ Theme และผ่านการตรวจสอบ Static Analysis, Automated Test, Manual Functional Test และ Release APK Build ก่อนส่งมอบ
