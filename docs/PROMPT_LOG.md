# Prompt Log — Home Asset Manager

รายการนี้สรุป Prompt/งานสำคัญที่ใช้ AI ช่วยพัฒนาโครงการ โดยเน้นสิ่งที่เกิดขึ้นจริงระหว่างการพัฒนา

1. ออกแบบแนวคิดแอปจัดการทรัพย์สินภายในบ้านและกำหนดขอบเขตโครงการ
2. วิเคราะห์ว่าควรมีหมวดหมู่ทรัพย์สินอะไรบ้าง
3. วิเคราะห์ว่าสถานที่ภายในบ้านควรมีอะไรบ้าง
4. ศึกษาเอกสาร/สไลด์รายวิชาเพื่อกำหนดแนวทางให้เหมาะกับบทเรียน
5. วาง Architecture แบบ Screen → Provider → Repository → DAO → SQLite
6. ตั้งค่า Flutter project และแก้ปัญหา `MyApp` ใน widget test
7. ออกแบบ Drift database สำหรับ Categories, Locations และ Assets
8. แก้ปัญหา Drift code generation / migration / import ambiguity
9. สร้าง CategoryProvider และหน้าจัดการหมวดหมู่
10. สร้าง LocationProvider และหน้าจัดการสถานที่
11. สร้าง AssetProvider และระบบ CRUD
12. เพิ่ม Search / Filter / Sort ให้รายการทรัพย์สิน
13. เพิ่ม Favorite ให้ทรัพย์สิน
14. เพิ่ม Warranty status และคำนวณวันคงเหลือ
15. เพิ่ม Maintenance records และคำนวณค่าใช้จ่ายรวม
16. เพิ่ม Local Notification สำหรับ warranty
17. เพิ่ม QR Generate และ QR Scanner
18. แก้ปัญหา package dependency ระหว่าง file_picker และ share_plus
19. เพิ่ม Save / Share / Print QR Code และแก้ปัญหา PdfColors namespace
20. ตรวจสอบ `flutter analyze` และ `flutter test`
21. แก้ ProviderNotFoundException และตรวจ Provider registration ใน app shell
22. ปรับ UI/UX ของ Home, Asset List, Asset Card, Asset Form, Asset Detail, Statistics และ Settings
23. เพิ่ม Backup / Restore สำหรับข้อมูล SQLite
24. เพิ่ม app icon และตั้งค่า flutter_launcher_icons
25. ทดสอบฟังก์ชันหลักบน Android เครื่องจริง
26. Build Release APK และทดสอบ APK ตัวจริง

## ตัวอย่างปัญหาที่ AI ช่วยแก้
- Test widget อ้าง class ที่ไม่มีอยู่
- Provider ไม่ถูก inject ใน widget tree
- Drift migration และ generated code
- controller ถูก dispose เร็วเกินไปใน dialog
- package dependency conflict
- PDF API / namespace
- QR scanner และ validation

## AI ช่วยอะไร
AI ช่วยในการออกแบบโครงสร้าง วิเคราะห์ error เขียนโค้ดตัวอย่าง ตรวจแนวทางแก้ไข และช่วยวางลำดับการทดสอบ

## AI ทำพลาดอะไร
AI บางครั้งให้โค้ดที่ไม่ตรงกับโครงสร้างไฟล์ปัจจุบัน เช่น อ้าง scope ของตัวแปรผิดตำแหน่ง, แนะนำ API/package version ที่ไม่ตรงกับ dependency ปัจจุบัน หรือทำให้ไฟล์ถูกแก้ผิดหน้าที่ จึงต้องตรวจ `flutter analyze`, `flutter test` และทดสอบบนเครื่องจริงทุกครั้ง

## บทเรียน
AI เป็นเครื่องมือช่วยพัฒนา ไม่ใช่ตัวแทนการตรวจสอบ นักพัฒนาต้องตรวจ code, dependency, architecture และผลการทำงานจริงก่อนยืนยันว่าเสร็จ
