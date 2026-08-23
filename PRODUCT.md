# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

Inferred from the existing role model: citizens submit and track municipal service requests; dispatchers, supervisors, department administrators, and system administrators triage requests and operate work orders.

## Product Purpose

Inferred from the existing NUI and API: CivicOS gives a FiveM municipal-operations team one place to submit requests, review their status, and move authorized work orders through field operations.

## Positioning

The interface joins citizen request intake with server-validated staff operations in the same role-aware NUI surface.

## Operating Context

Used inside a FiveM game session through the `/civicos` command. The interface opens and closes through NUI messages, calls the existing `civicos:api` transport, and is optimized for mouse and keyboard use at normal desktop FiveM resolutions.

## Capabilities and Constraints

- Preserve existing API operations, NUI message types, element IDs, role checks, request/work-order transitions, and form behavior.
- Existing surface supports bootstrap data, request listing, work-order listing for staff, service selection, request creation, refresh actions, and Escape/Close dismissal.
- No new product claims, backend behavior, dependencies, or external assets are required for this redesign.

## Brand Commitments

The product name “CivicOS” and the municipal-operations terminology are existing commitments. The user explicitly requested a from-scratch visual redesign and no non-visual behavior changes.

## Evidence on Hand

Existing artifact: `web/dist/index.html`. Existing API and role behavior: `web/src/`, `client/nui.lua`, and `server/api/callbacks.lua`. No approved logo or image assets are present.

## Product Principles

1. Keep every role-aware action understandable at a glance.
2. Put current operational state before decoration.
3. Preserve server authority and existing workflow semantics.
4. Make the same surface useful for citizens and staff.

## Accessibility & Inclusion

Inferred baseline: maintain readable contrast, visible keyboard focus, 44px controls, semantic form labels, status announcements, reduced-motion support, and a desktop-first workbench for the FiveM NUI surface.
