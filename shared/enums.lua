-- CivicOS S00 frozen domain enumerations.
--
-- Values in this module are public contract values. Services must import this
-- module instead of assigning lifecycle strings directly.

local CivicOS = rawget(_G, "CivicOS") or {}
_G.CivicOS = CivicOS

local Enums = {
    RequestStatus = {
        DRAFT = "draft",
        SUBMITTED = "submitted",
        TRIAGED = "triaged",
        ACCEPTED = "accepted",
        REJECTED = "rejected",
        DUPLICATE = "duplicate",
        ON_HOLD = "on_hold",
        CONVERTED = "converted",
        IN_PROGRESS = "in_progress",
        RESOLVED = "resolved",
        CLOSED = "closed",
        REOPENED = "reopened",
        WAITING_EXTERNAL = "waiting_external",
        CANCELLED = "cancelled",
    },

    WorkOrderStatus = {
        CREATED = "created",
        UNASSIGNED = "unassigned",
        ASSIGNED = "assigned",
        ACKNOWLEDGED = "acknowledged",
        DECLINED = "declined",
        REASSIGNED = "reassigned",
        EN_ROUTE = "en_route",
        ON_SCENE = "on_scene",
        WORKING = "working",
        BLOCKED = "blocked",
        ON_HOLD = "on_hold",
        PENDING_INSPECTION = "pending_inspection",
        COMPLETED = "completed",
        FAILED = "failed",
        REWORK_REQUIRED = "rework_required",
        CLOSED = "closed",
        CANCELLED = "cancelled",
    },

    AssignmentStatus = {
        PENDING = "pending",
        OFFERED = "offered",
        ACCEPTED = "accepted",
        DECLINED = "declined",
        ACTIVE = "active",
        RELEASED = "released",
        COMPLETED = "completed",
        EXPIRED = "expired",
    },

    CrewStatus = {
        ACTIVE = "active",
        INACTIVE = "inactive",
        DISBANDED = "disbanded",
    },

    Priority = {
        LOW = "low",
        NORMAL = "normal",
        HIGH = "high",
        URGENT = "urgent",
        CRITICAL = "critical",
    },

    DutyStatus = {
        OFF_DUTY = "off_duty",
        ON_DUTY = "on_duty",
        UNAVAILABLE = "unavailable",
    },

    AvailabilityStatus = {
        AVAILABLE = "available",
        BUSY = "busy",
        AWAY = "away",
        OFFLINE = "offline",
    },

    InspectionStatus = {
        NOT_REQUIRED = "not_required",
        PENDING = "pending",
        PASSED = "passed",
        FAILED = "failed",
        REWORK_REQUIRED = "rework_required",
    },

    SlaStatus = {
        PENDING = "pending",
        MET = "met",
        BREACHED = "breached",
        PAUSED = "paused",
        CANCELLED = "cancelled",
    },

    EvidenceType = {
        PHOTO = "photo",
        VIDEO = "video",
        DOCUMENT = "document",
        EXTERNAL_URL = "external_url",
    },

    AuditAction = {
        CREATE = "create",
        UPDATE = "update",
        TRANSITION = "transition",
        ASSIGN = "assign",
        UNASSIGN = "unassign",
        DELETE = "delete",
        EXPORT = "export",
        LOGIN = "login",
        SECURITY_REJECT = "security_reject",
    },

    FrameworkProvider = {
        AUTO = "auto",
        QBCORE = "qbcore",
        QBOX = "qbox",
        ESX = "esx",
        STANDALONE = "standalone",
    },

    DutyMode = {
        AUTO = "auto",
        FRAMEWORK = "framework",
        CIVICOS = "civicos",
    },
}

CivicOS.Enums = Enums
return Enums
