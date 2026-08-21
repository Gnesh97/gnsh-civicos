# CivicOS Terminology & Enum Freeze

Bu belge CivicOS v1 çekirdek sözleşmesindeki terimleri ve lifecycle değerlerini
freeze eder. Kod tarafındaki tek kaynak `shared/enums.lua` dosyasıdır.

## Domain terimleri

| Terim | Tanım | Sınır |
|---|---|---|
| Request | Citizen, staff veya entegrasyon tarafından açılan hizmet talebi. | Talep yaşam döngüsünü ve citizen-safe timeline'ı taşır. |
| Work Order | Kabul edilmiş request'i sahada yürütülebilir operasyona dönüştüren iş emri. | Assignment, checklist, SLA ve field action kapsamını taşır. |
| Assignment | Work Order'ın employee veya crew'a scope kontrollü atanması. | Tekil atomik assignment işlemiyle oluşturulur. |
| Crew | Bir Work Order üzerinde birlikte çalışan employee grubu. | Crew üyeliği ve katkı kayıtları ayrı tutulur. |
| Department | Hizmetleri ve çalışanları yöneten belediye organizasyon birimi. | Permission scope için temel sınırdır. |
| Employee | Bir framework identity'siyle eşleşen, CivicOS operasyon profiline sahip çalışan. | Job, duty, availability ve certification bilgisi normalize edilir. |
| Inspection | Completion öncesi veya sonrası iş kalitesini doğrulayan kontrollü inceleme. | Pass/fail/rework kararı verir; internal notlar citizen'a açılmaz. |
| SLA | Request/work-order milestone'ları için kalıcı due, pause, met ve breach ölçümü. | Restart sonrası devam eder; entity başına thread oluşturulmaz. |
| Evidence | Fotoğraf, video, belge veya external URL metadata'sı. | Provider abstraction üzerinden bağlanır; CivicOS screenshot scriptine kilitlenmez. |
| Audit | Kim, ne zaman, hangi entity üzerinde hangi kritik değişikliği yaptı kaydı. | PII redaction uygulanır; activity timeline ile aynı değildir. |
| Activity timeline | Citizen veya staff rolüne göre filtrelenmiş durum geçmişi. | Raw audit payload'ı yerine permission-scoped DTO döner. |
| Integration | Public export/event/API kontratını kullanan harici resource. | Core'a özel-case eklemez. |
| Actor | İşlemi gerçekleştiren authenticated player, system job veya integration identity'si. | Permission ve scope değerlendirmesinin girdisidir. |
| Expected version | Optimistic concurrency için client'ın gördüğü entity sürümü. | Eşleşmezse silent overwrite yerine conflict döner. |

## Request status

| Key | Value | Anlam |
|---|---|---|
| `DRAFT` | `draft` | Henüz submit edilmemiş taslak. |
| `SUBMITTED` | `submitted` | Server validation'dan geçen yeni talep. |
| `TRIAGED` | `triaged` | Dispatcher tarafından sınıflandırılmış talep. |
| `ACCEPTED` | `accepted` | Operasyon için kabul edilmiş talep. |
| `REJECTED` | `rejected` | İşletme kurallarıyla reddedilmiş talep. |
| `DUPLICATE` | `duplicate` | Başka aktif talep ile aynı olduğu işaretlenmiş talep. |
| `ON_HOLD` | `on_hold` | Geçici dış bağımlılık veya operasyon sebebiyle bekleyen talep. |
| `CONVERTED` | `converted` | Work Order'a dönüştürülmüş talep. |
| `IN_PROGRESS` | `in_progress` | Bağlı operasyon yürütülüyor. |
| `RESOLVED` | `resolved` | Çözüm kaydedildi, kapanış doğrulaması beklenebilir. |
| `CLOSED` | `closed` | Talep yaşam döngüsü tamamlandı. |
| `REOPENED` | `reopened` | Kapatılmış talep yeniden incelemeye açıldı. |
| `WAITING_EXTERNAL` | `waiting_external` | Harici provider veya kurum yanıtı bekleniyor. |
| `CANCELLED` | `cancelled` | Talep yetkili bir aktör tarafından iptal edildi. |

İzinli geçişler S05'te uygulanacak state machine tarafından yönetilir:

```text
DRAFT -> SUBMITTED
SUBMITTED -> TRIAGED | CANCELLED
TRIAGED -> ACCEPTED | REJECTED | DUPLICATE | ON_HOLD
ACCEPTED -> CONVERTED | ON_HOLD | CANCELLED
CONVERTED -> IN_PROGRESS
IN_PROGRESS -> RESOLVED | ON_HOLD | WAITING_EXTERNAL
RESOLVED -> CLOSED | REOPENED
REOPENED -> TRIAGED | IN_PROGRESS
ON_HOLD -> TRIAGED | ACCEPTED | IN_PROGRESS | CANCELLED
WAITING_EXTERNAL -> IN_PROGRESS | RESOLVED | CANCELLED
```

## Work Order status

```text
CREATED -> UNASSIGNED
UNASSIGNED -> ASSIGNED | CANCELLED
ASSIGNED -> ACKNOWLEDGED | DECLINED | REASSIGNED | CANCELLED
ACKNOWLEDGED -> EN_ROUTE | ON_HOLD | REASSIGNED
EN_ROUTE -> ON_SCENE | ON_HOLD | REASSIGNED
ON_SCENE -> WORKING | BLOCKED | ON_HOLD
WORKING -> PENDING_INSPECTION | COMPLETED | BLOCKED | FAILED
PENDING_INSPECTION -> COMPLETED | REWORK_REQUIRED
REWORK_REQUIRED -> WORKING
COMPLETED -> CLOSED
BLOCKED -> WORKING | ON_HOLD | CANCELLED
```

## Operasyon enum'ları

- `Priority`: `low`, `normal`, `high`, `urgent`, `critical`
- `DutyStatus`: `off_duty`, `on_duty`, `unavailable`
- `AvailabilityStatus`: `available`, `busy`, `away`, `offline`
- `InspectionStatus`: `not_required`, `pending`, `passed`, `failed`, `rework_required`
- `SlaStatus`: `pending`, `met`, `breached`, `paused`, `cancelled`
- `AssignmentStatus`: `pending`, `offered`, `accepted`, `declined`, `active`,
  `released`, `completed`, `expired`
- `CrewStatus`: `active`, `inactive`, `disbanded`
- `EvidenceType`: `photo`, `video`, `document`, `external_url`
- `AuditAction`: `create`, `update`, `transition`, `assign`, `unassign`, `delete`,
  `export`, `login`, `security_reject`

## Normalized identity

Framework adapter core'a şu şekli verir; native player/job objesi core'a taşınmaz:

```lua
{
    source = 31,
    persistentIdentifier = "...",
    characterId = "...",
    displayName = "John Doe",
    framework = "qbox",
    job = {
        name = "publicworks",
        label = "Public Works",
        grade = 2,
        gradeName = "technician",
        onDuty = true
    }
}
```

Framework provider değerleri `auto`, `qbcore`, `qbox`, `esx` ve `standalone`;
duty mode değerleri `auto`, `framework` ve `civicos`'tur.
