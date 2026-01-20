# Technology Stack

## Overview
This project leverages a modern, cross-platform technology stack focused on efficiency, performance, and developer experience.

## Core Technologies
-   **Programming Language:** Dart
-   **Framework:** Flutter (for cross-platform mobile and potentially web development)
-   **Backend & Database:** Supabase = Postgres + Auth + RLS + migrations (realtime is optional, not required).
-   **Payments:** Stripe on web only (Checkout + Customer Portal). Mobile app has no in-app purchases; it only gates access based on subscription_status in Supabase.
-   **Signup:** Account creation happens on web; app is login-only + AccountStatusGate.

## Architecture
The application is structured with a layered or MVVM-like architecture, promoting separation of concerns and maintainability. This includes distinct layers for:
-   Presentation (UI components, screens, widgets)
-   Business Logic (viewmodels, providers)
-   Data Access (repositories, services)

## Reporting
-   **Reporting:** In-app Excel (XLSX) + CSV export generation.

## Maps/travel (optional, privacy-safe)
-   **Optional Google Maps/Places autocomplete + on-demand travel time estimation (no background GPS tracking; cache to control cost).**