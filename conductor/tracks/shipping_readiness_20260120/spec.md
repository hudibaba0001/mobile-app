# Specification: Shipping Readiness: Remove Admin + Lock Core Journey + Excel Export

## 1. Overview
This track focuses on preparing the application for its initial release by removing administrative features from the production build, solidifying the core user journey, and implementing the essential Excel (XLSX) and CSV export functionality. The goal is to deliver a stable, user-friendly, and trustworthy MVP that provides immediate value to the end-user.

## 2. Key Deliverables

### 2.1. Admin Feature Removal
- **Objective:** Ensure no administrative features, screens, or routes are present in the production user-facing application.
- **Requirements:**
    - All admin-related screens must be disabled or removed from the production navigation graph.
    - API calls to admin-only endpoints should be removed from the user build.
    - All tests related to admin functionality should be moved to a separate test suite or disabled for the production build to ensure a green CI pipeline.

### 2.2. Core Journey Solidification
- **Objective:** Create a seamless and logical flow for the primary user journey, from login to daily use.
- **Requirements:**
    - **Login:** Users must be able to log in to the application.
    - **Account Status Gate:** After login, the app must check the user's subscription status. Access to the main app functionality should be granted only to users with a `trialing` or `active` status.
    - **Home Screen:** The home screen must prominently display the current month's time balance ("plus/minus vs target") as the primary information card.
    - **Daily Logging:** The daily logging feature must be fast and intuitive, allowing users to log up to two shifts and their travel minutes quickly.

### 2.3. Export Functionality
- **Objective:** Implement reliable and consistent export functionality for both Excel (XLSX) and CSV formats.
- **Requirements:**
    - Implement a canonical data structure (e.g., `List<String> headers` and `List<List<dynamic>> rows`) to serve as a single source of truth for both exporters.
    - Create a `CsvExporter` that generates a CSV file from the canonical data structure.
    - Create an `XlsxExporter` that generates an Excel (XLSX) file from the same canonical data structure.
    - Ensure that the generated totals and all other data points are identical across both the CSV and Excel exports.

### 2.4. Regression & Smoke Testing
- **Objective:** Verify that the core application functions as expected after the changes in this track.
- **Requirements:**
    - The application must boot without crashing.
    - The Account Status Gate must correctly block or allow users based on their subscription status.
    - The export functionality must be invokable without crashing the application.
    - The time balance screen must load and display data correctly.

## 3. Rationale
This track is prioritized to:
- **Remove Distractions:** Eliminating admin features simplifies the user experience and reduces potential confusion.
- **Improve Trust and UX:** A locked-down, logical core journey builds user confidence.
- **Deliver Core Value:** The export feature is the primary "proof" that empowers users to verify their payroll, which is the app's main selling point.
