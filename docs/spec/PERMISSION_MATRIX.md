# CivicOS Permission Matrix

Bu matris S04 RBAC implementasyonu için freeze edilmiş authorization
sözleşmesidir. Permission key'leri `config/permissions.lua` içindeki tek
kaynaktan gelir. Role label'ı tek başına yetki değildir.

## Scope modeli

| Scope | Anlam | Örnek |
|---|---|---|
| `own` | Actor'ın kendi oluşturduğu veya kendi identity'siyle bağlı kaynak. | Citizen kendi request yorumunu ekler. |
| `assigned` | Actor'a veya actor'ın crew'una atanmış aktif Work Order. | Technician yalnızca assigned field action yapar. |
| `department` | Actor'ın aktif department kapsamındaki kaynaklar. | Dispatcher queue ve assignment görür. |
| `global` | Sistem genelinde yönetim. | System Admin config ve tüm audit kayıtlarını görür. |

Department scope her istekte server-side actor department, target department ve
role grant karşılaştırmasıyla doğrulanır. `global` scope bile authentication,
entity existence, state, version ve audit kontrollerini atlamaz.

## Rol matrisi

| Rol | Scope | Temel yetenek |
|---|---|---|
| `CITIZEN` | own | Request oluşturma, kendi talebini/timeline'ını görme, public yorum. |
| `TECHNICIAN` | assigned | Self-assign, atanmış Work Order, field action, checklist, evidence, duty. |
| `DISPATCHER` | department | Queue triage, kabul/reject, conversion, assignment, dependency. |
| `SUPERVISOR` | department | Dispatcher yetkileri, cancel/reopen, SLA/audit/analytics. |
| `DEPARTMENT_ADMIN` | department | Workforce, certification, department ve SLA yönetimi. |
| `SYSTEM_ADMIN` | global | Tüm operasyonlar, config ve global audit/analytics. |

## Kritik server action mapping

| Server action | Gerekli permission | Scope / ek kontrol |
|---|---|---|
| CreateRequest | `request.create` | Auth, schema, rate limit, location ve duplicate. |
| ReadOwnRequest | `request.read.own` | Request owner veya public DTO. |
| TriageRequest | `request.triage` | Department queue, current state, expected version. |
| Accept/RejectRequest | `request.accept` / `request.reject` | Department scope ve transition guard. |
| ConvertRequest | `request.convert` | Catalog/template ve transaction. |
| AddInternalComment | `request.comment.internal` | Staff role, department scope, citizen DTO'dan ayrı. |
| ReadAssignedWorkOrder | `workorder.read.assigned` | Assignment/crew membership. |
| CreateWorkOrder | `workorder.create` | Department scope, template, source request. |
| AssignWorkOrder | `workorder.assign` | Department, certification, availability, atomic version. |
| SelfAssign | `workorder.self_assign` | On-duty, certification, unassigned state, atomic update. |
| UpdateFieldAction | `field.action.execute` | Assignment, state, distance, one-time action token. |
| UpdateChecklist | `field.checklist.update` | Assigned Work Order, schema and item rules. |
| AttachEvidence | `field.evidence.attach` | Provider metadata validation and assignment scope. |
| InspectWorkOrder | `field.inspection.execute` | Inspector role, inspection state and audit. |
| ManageEmployees | `employee.manage` | Department admin scope, no raw framework object. |
| ManageCertifications | `employee.certification.manage` | Department admin scope, audit. |
| ManageSla | `sla.manage` | Supervisor/admin scope, UTC due timestamps. |
| ReadAudit | `audit.read` | Role scope, PII redaction, pagination. |
| ReadAnalytics | `analytics.read` | Bounded date range, permission-scoped read model. |
| ManageSystemConfig | `system.config.manage` | System Admin only, validation and restart note. |

## Deny-by-default kuralları

1. Tanımsız permission key veya rol deny edilir.
2. Permission mevcut olsa bile actor authenticated değilse deny edilir.
3. Own/assigned/department scope uyuşmuyorsa deny edilir.
4. State, expected version, rate limit, distance veya token kontrolü başarısızsa
   permission sonucu grant olsa bile işlem başarısız olur.
5. Internal comment, raw audit ve framework identifier'ları citizen payload'ına
   gönderilmez.
