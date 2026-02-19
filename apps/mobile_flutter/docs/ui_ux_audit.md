# UI/UX Audit & Improvement Plan

## Executive Summary
The application has a solid design foundation using Material 3 principles and a robust `AppTheme` system. However, several areas can be refined to elevate the "premium" feel, improve information density, and ensure visual consistency across all screens.

## 1. Visual Hierarchy & Spacing (Global)
**Observation:** While `AppSpacing` is used throughout, some cards and lists feel either too dense or disjointed.
**Recommendation:**
- **Standardize Card Padding:** Ensure all primary cards (`FlexsaldoCard`, `TotalCard`, etc.) use a consistent internal padding (likely `AppSpacing.lg` or `AppSpacing.xl` for "hero" cards).
- **Section Gaps:** Increase the vertical spacing between major homepage sections (e.g., between "This Week" stats and "Recent Entries") to `AppSpacing.xxl` to let the content breathe.
- **Typography:** Use the `dmsans` font family (already in `pubspec.yaml`? need to verify) or a similar premium geometric sans-serif to replace the default Roboto/System font for headers (`display`, `headline`, `title`). Keep the system font for body text for readability.

## 2. Unified Home Screen
**Observation:** The "Today" and "This Week" cards are functional but visually separate. The "Recent Entries" list is a simple column.
**Improvements:**
- **Hero Stats:** Combine "Today" and "This Week" into a single, swipeable "Pulse" card or a tighter grid layout to reduce vertical scrolling.
- **Gradient Consistency:** The gradients on the summary cards (`primary` to `primary.withOpacity(0.85)`) are good, but could be subtler or use a mesh gradient for a more modern look.
- **Recent Entries:**
    - Add a distinct "sticky" header for the list.
    - Use a timeline connector line (vertical dots) between entry icons to visually link the day's activities.
    - Improve the "empty state" for recent entries to be more inviting (e.g., an illustration instead of just text/shimmers).

## 3. Reports Tab (Overview & Trends)
**Observation:** The segment controls (Chips) at the top of Overview are functional but standard.
**Improvements:**
- **Segment Control:** Replace standard `ChoiceChip` with a custom-styled `SegmentedButton` or a sliding tab indicator for a more app-like feel.
- **Data Visualization:**
    - **Trends Chart:** The weekly hours bar chart is clean but could use rounded top corners (already present?) and a "goal line" overlay (dotted line for target hours).
    - **Monthly Cards:** The "delta" text indicates status with color, but a small arrow icon ($\uparrow$ / $\downarrow$) would instantly communicate trend direction without reading.

## 4. Entry Details & Dialogs
**Observation:** "Entry Detail" is a bottom sheet, while "Absence" is a full dialog.
**Improvements:**
- **Consistency:** Move Absence adding/editing to a **Modal Bottom Sheet** to match the Entry Detail interaction pattern. Bottom sheets are generally more ergonomic on mobile.
- **Input Controls:**
    - The "Minutes" slider in the Absence dialog is a bit imprecise. Add `+/-` stepper buttons or a direct text input for precise control.
    - Date pickers should feel integrated; consider a calendar strip for quick date selection if frequent.

## 5. Micro-Interactions
**Observation:** The app is functional but static.
**Improvements:**
- **Button Press:** Add scale-down animations (`ScaleTransition`) on card taps.
- **Loading States:** Ensure all shimmer effects (`_ShimmerBox`) match the exact shape/border-radius of the content they replace to avoid layout shifts.
- **Feedback:** Add haptic feedback (using `HapticFeedback.lightImpact()`) to primary actions like "Start Timer" or "Save Entry".

## Action Plan
1.  **Refine Typography:** Update `AppTheme` to use a premium header font.
2.  **Polish Home:** Update the spacing and add the timeline visual to "Recent Entries".
3.  **Standardize Inputs:** Convert Absence Dialog to a Bottom Sheet.
4.  **Enhance Graphs:** Add the target line to the Trends bar chart.
