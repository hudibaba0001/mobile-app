# Implementation Plan: Shipping Readiness: Remove Admin + Lock Core Journey + Excel Export

## Phase 1: Admin Feature Removal & Code Cleanup

- [ ] **Task:** Identify and list all admin-related screens, routes, and widgets in the codebase.
- [ ] **Task:** Create a build-time configuration (e.g., using environment variables or a separate `main_prod.dart`) to conditionally exclude admin features from the production build.
- [ ] **Task:** Refactor the navigation system to remove or disable all routes to admin screens in the production build.
- [ ] **Task:** Isolate admin-specific tests. Create a separate test suite for admin tests that does not run as part of the main CI/CD pipeline for production builds.
- [ ] **Task:** Run the test suite and ensure all tests pass and that no admin-related code is present in the production build.
- [ ] **Task:** Conductor - User Manual Verification 'Admin Feature Removal & Code Cleanup' (Protocol in workflow.md)

## Phase 2: Core Journey Implementation

- [ ] **Task:** Implement the `AccountStatusGate` widget that checks the user's subscription status from Supabase after login.
    - [ ] **Sub-task:** If the status is `trialing` or `active`, allow the user to proceed to the home screen.
    - [ ] **Sub-task:** If the status is anything else, block the user with a message and a link to the web-based customer portal.
- [ ] **Task:** Implement the home screen's main card to display the current month's "plus/minus vs target" time balance.
    - [ ] **Sub-task:** Fetch the necessary data (worked hours, target hours, etc.) for the current month.
    - [ ] **Sub-task:** Calculate and display the time balance prominently.
- [ ] **Task:** Review and optimize the daily logging flow to ensure it's fast and supports two shifts plus travel time.
- [ ] **Task:** Conductor - User Manual Verification 'Core Journey Implementation' (Protocol in workflow.md)

## Phase 3: Export Functionality

- [ ] **Task:** Design and implement the canonical data structure for the export data (`List<String> headers`, `List<List<dynamic>> rows`).
- [ ] **Task:** Implement the `CsvExporter` service.
    - [ ] **Sub-task:** Write tests for the `CsvExporter`.
- [ ] **Task:** Implement the `XlsxExporter` service using the `excel` package.
    - [ ] **Sub-task:** Write tests for the `XlsxExporter`.
- [ ] **Task:** Integrate the exporters into the UI with a one-tap export button.
- [ ] **Task:** Conductor - User Manual Verification 'Export Functionality' (Protocol in workflow.md)

## Phase 4: Regression Testing & Finalization

- [ ] **Task:** Write and run smoke tests for the core application functionality:
    - [ ] **Sub-task:** Test that the app boots successfully.
    - [ ] **Sub-task:** Test the `AccountStatusGate` with both allowed and blocked users.
    - [ ] **Sub-task:** Test that the export function can be triggered without crashing.
    - [ ] **Sub-task:** Test that the time balance screen loads correctly.
- [ ] **Task:** Manually test the end-to-end user flow.
- [ ] **Task:** Conductor - User Manual Verification 'Regression Testing & Finalization' (Protocol in workflow.md)
