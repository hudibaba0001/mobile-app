-- Fix mutable search_path for security
ALTER FUNCTION public.update_balance_adjustments_updated_at() SET search_path = public;
ALTER FUNCTION public.update_updated_at_column() SET search_path = public;

-- Optimize RLS policies to avoid per-row auth function evaluation
ALTER POLICY "Users can update own profile limited" ON public.profiles
  USING ((select auth.uid()) = id)
  WITH CHECK ((select auth.uid()) = id);
ALTER POLICY "Users can view own profile" ON public.profiles
  USING ((select auth.uid()) = id);

ALTER POLICY "Users can delete their own red days" ON public.user_red_days
  USING ((select auth.uid()) = user_id);
ALTER POLICY "Users can insert their own red days" ON public.user_red_days
  WITH CHECK ((select auth.uid()) = user_id);
ALTER POLICY "Users can update their own red days" ON public.user_red_days
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);
ALTER POLICY "Users can view their own red days" ON public.user_red_days
  USING ((select auth.uid()) = user_id);

ALTER POLICY "Users can delete their own entries" ON public.entries
  USING ((select auth.uid()) = user_id);
ALTER POLICY "Users can insert their own entries" ON public.entries
  WITH CHECK ((select auth.uid()) = user_id);
ALTER POLICY "Users can update their own entries" ON public.entries
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);
ALTER POLICY "Users can view their own entries" ON public.entries
  USING ((select auth.uid()) = user_id);

ALTER POLICY "Users can delete their own adjustments" ON public.balance_adjustments
  USING ((select auth.uid()) = user_id);
ALTER POLICY "Users can insert their own adjustments" ON public.balance_adjustments
  WITH CHECK ((select auth.uid()) = user_id);
ALTER POLICY "Users can update their own adjustments" ON public.balance_adjustments
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);
ALTER POLICY "Users can view their own adjustments" ON public.balance_adjustments
  USING ((select auth.uid()) = user_id);

ALTER POLICY "Users can delete their own travel segments" ON public.travel_segments
  USING (
    EXISTS (
      SELECT 1
      FROM entries
      WHERE entries.id = travel_segments.entry_id
        AND entries.user_id = (select auth.uid())
    )
  );
ALTER POLICY "Users can insert their own travel segments" ON public.travel_segments
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM entries
      WHERE entries.id = travel_segments.entry_id
        AND entries.user_id = (select auth.uid())
    )
  );
ALTER POLICY "Users can update their own travel segments" ON public.travel_segments
  USING (
    EXISTS (
      SELECT 1
      FROM entries
      WHERE entries.id = travel_segments.entry_id
        AND entries.user_id = (select auth.uid())
    )
  );
ALTER POLICY "Users can view their own travel segments" ON public.travel_segments
  USING (
    EXISTS (
      SELECT 1
      FROM entries
      WHERE entries.id = travel_segments.entry_id
        AND entries.user_id = (select auth.uid())
    )
  );

ALTER POLICY "Users can delete their own work shifts" ON public.work_shifts
  USING (
    EXISTS (
      SELECT 1
      FROM entries
      WHERE entries.id = work_shifts.entry_id
        AND entries.user_id = (select auth.uid())
    )
  );
ALTER POLICY "Users can insert their own work shifts" ON public.work_shifts
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM entries
      WHERE entries.id = work_shifts.entry_id
        AND entries.user_id = (select auth.uid())
    )
  );
ALTER POLICY "Users can update their own work shifts" ON public.work_shifts
  USING (
    EXISTS (
      SELECT 1
      FROM entries
      WHERE entries.id = work_shifts.entry_id
        AND entries.user_id = (select auth.uid())
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1
      FROM entries
      WHERE entries.id = work_shifts.entry_id
        AND entries.user_id = (select auth.uid())
    )
  );
ALTER POLICY "Users can view their own work shifts" ON public.work_shifts
  USING (
    EXISTS (
      SELECT 1
      FROM entries
      WHERE entries.id = work_shifts.entry_id
        AND entries.user_id = (select auth.uid())
    )
  );

ALTER POLICY "Users can delete own absences" ON public.absences
  USING ((select auth.uid()) = user_id);
ALTER POLICY "Users can insert own absences" ON public.absences
  WITH CHECK ((select auth.uid()) = user_id);
ALTER POLICY "Users can select own absences" ON public.absences
  USING ((select auth.uid()) = user_id);
ALTER POLICY "Users can update own absences" ON public.absences
  USING ((select auth.uid()) = user_id)
  WITH CHECK ((select auth.uid()) = user_id);

-- Remove duplicate/unused indexes flagged by lint
DROP INDEX IF EXISTS public.idx_profiles_subscription;
DROP INDEX IF EXISTS public.user_red_days_user_id_idx;
DROP INDEX IF EXISTS public.user_red_days_date_idx;
DROP INDEX IF EXISTS public.idx_entries_user_id;
DROP INDEX IF EXISTS public.idx_entries_date;
DROP INDEX IF EXISTS public.idx_entries_type;
DROP INDEX IF EXISTS public.entries_date_idx;
DROP INDEX IF EXISTS public.entries_type_idx;
DROP INDEX IF EXISTS public.entries_user_date_idx;
DROP INDEX IF EXISTS public.entries_is_holiday_work_idx;
DROP INDEX IF EXISTS public.idx_work_shifts_time_range;
DROP INDEX IF EXISTS public.idx_work_shifts_entry_id;
