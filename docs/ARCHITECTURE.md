# Architecture Diagram

## Layered Architecture

```text
                    USER
                     │
                     ▼
┌─────────────────────────────────────┐
│ UI Layer                            │
│ Screen / Widget                     │
│ - Home                              │
│ - Assets                            │
│ - Asset Detail / Form               │
│ - Statistics                        │
│ - Settings                          │
│ - QR / Maintenance                  │
└──────────────────┬──────────────────┘
                   │
                   ▼
┌─────────────────────────────────────┐
│ State Layer                         │
│ Provider / ChangeNotifier           │
│ - AssetProvider                     │
│ - CategoryProvider                  │
│ - LocationProvider                  │
│ - MaintenanceProvider               │
│ - ThemeProvider                     │
└──────────────────┬──────────────────┘
                   │
                   ▼
┌─────────────────────────────────────┐
│ Repository Layer                    │
│ - AssetRepository                   │
│ - CategoryRepository                │
│ - LocationRepository                │
│ - MaintenanceRepository             │
└──────────────────┬──────────────────┘
                   │
                   ▼
┌─────────────────────────────────────┐
│ Data Access Layer                   │
│ Drift DAO                           │
│ - AssetDao                          │
│ - CategoryDao                       │
│ - LocationDao                      │
│ - MaintenanceDao                    │
└──────────────────┬──────────────────┘
                   │
                   ▼
┌─────────────────────────────────────┐
│ Local Database                      │
│ SQLite + Drift                      │
└─────────────────────────────────────┘
```

## Supporting Services
- NotificationService → local warranty notifications
- BackupService → export / restore local data
- Image handling → image_picker / local file path
- QR → qr_flutter + mobile_scanner
- PDF / Share / Print → pdf + printing + share_plus
