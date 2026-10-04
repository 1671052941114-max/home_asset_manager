# Secure Coding / OWASP Checklist

เอกสารนี้ใช้เป็นหลักฐานประกอบการตรวจสอบด้านความปลอดภัยของแอปในรูปแบบที่เหมาะกับแอป Local-first

## 1. Input Validation
สถานะ: Implemented

- ตรวจสอบข้อมูลที่ผู้ใช้กรอกก่อนบันทึก
- ตรวจสอบค่าที่ต้องเป็นตัวเลข เช่น ราคา
- ตรวจสอบข้อมูลวันที่
- ตรวจสอบชื่อที่ว่าง
- ตรวจสอบ QR payload ก่อนใช้เป็น Asset ID

## 2. Database Safety
สถานะ: Implemented

- ใช้ Drift DAO สำหรับการเข้าถึง SQLite
- ไม่สร้าง SQL string จาก input ผู้ใช้โดยตรงใน flow ปกติ
- ใช้ typed queries ของ Drift

## 3. Access to Local Files
สถานะ: Implemented with limitations

- ตรวจสอบ path ก่อนเปิดรูป
- ใช้ file picker สำหรับการเลือกไฟล์ backup
- ไม่รับคำสั่ง shell จากผู้ใช้

## 4. Sensitive Data
สถานะ: Low-risk local application

แอปไม่มีระบบบัญชีผู้ใช้ ไม่มี password และไม่มีข้อมูล authentication ของผู้ใช้

## 5. Error Handling
สถานะ: Implemented

- Provider มี error state
- UI แสดง error/empty/loading state
- ไม่ควรแสดง stack trace หรือรายละเอียดฐานข้อมูลแก่ผู้ใช้โดยตรง

## 6. QR Validation
สถานะ: Implemented

QR ของระบบใช้รูปแบบ:

```text
HAM-ASSET-<assetId>
```

Scanner ตรวจ prefix และตรวจว่า ID เป็นจำนวนเต็มบวกก่อนค้นหาในฐานข้อมูล

## 7. Backup / Restore
สถานะ: Implemented

- ตรวจสอบโครงสร้าง backup ก่อน restore
- Restore เป็น operation ที่เปลี่ยนข้อมูลจำนวนมาก จึงควรให้ผู้ใช้ยืนยัน
- ไม่ควร restore ไฟล์จากแหล่งที่ไม่น่าเชื่อถือ

## 8. Notification Permission
สถานะ: Implemented

ระบบขอ notification permission บน Android และสร้าง notification channel สำหรับการแจ้งเตือนประกัน

## 9. Threat Model

| Threat | Impact | Mitigation |
|---|---|---|
| ผู้ใช้เลือก backup ที่เสียหาย | Medium | ตรวจ schema/version และ structure |
| QR ปลอม | Low | ตรวจ prefix + Asset ID + ค้นหาใน DB |
| ไฟล์รูปถูกลบ/ย้าย | Low | แสดง placeholder/error แทนการทำให้แอปล้ม |
| ข้อมูลในเครื่องสูญหาย | High | มี Backup / Restore |
| ผู้ใช้กดลบข้อมูลผิด | Medium | มี confirmation dialog |
| Notification ถูกปิดโดย Android | Low | แอปไม่พังและยังแสดงสถานะ warranty ใน UI |

## 10. ข้อจำกัดด้าน Security
แอปนี้ไม่ได้ออกแบบสำหรับข้อมูลลับระดับสูง เนื่องจากเป็นระบบจัดการทรัพย์สินส่วนบุคคลแบบ local application และไม่มี authentication/encryption-at-rest ในขอบเขตของโครงการนี้
