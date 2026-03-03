-- Time balance aggregate RPC for date-bounded Home/Time Balance calculations
--
-- Notes:
-- - Uses user_red_days for personal custom red days.
-- - Includes Swedish public holiday detection in SQL (same holiday set as app).
-- - IMPORTANT: is_swedish_public_holiday(...) is a server-side mirror of
--   apps/mobile_flutter/lib/calendar/sweden_holidays.dart.
--   If holiday logic changes in the app calendar, update this SQL function
--   in lockstep to keep RPC and client parity.
-- - Travel inclusion is toggled by p_travel_enabled.
-- - Leave credit is capped per day to planned minutes and allocated
--   deterministically by absence type + id.

-- Ensure personal red-day lookups stay indexed in environments where
-- the standalone user_red_days migration may not have been applied.
CREATE INDEX IF NOT EXISTS user_red_days_user_date_range_idx
  ON public.user_red_days(user_id, date);

CREATE OR REPLACE FUNCTION public.is_swedish_public_holiday(
  p_day date
)
RETURNS boolean
LANGUAGE plpgsql
IMMUTABLE
AS $$
DECLARE
  v_year integer;
  v_month integer;
  v_day integer;
  a integer;
  b integer;
  c integer;
  d integer;
  e integer;
  f integer;
  g integer;
  h integer;
  i integer;
  k integer;
  l integer;
  m integer;
  easter_month integer;
  easter_day integer;
  easter_sunday date;
  midsummer_day date;
  all_saints_day date;
BEGIN
  IF p_day IS NULL THEN
    RETURN FALSE;
  END IF;

  v_year := EXTRACT(YEAR FROM p_day);
  v_month := EXTRACT(MONTH FROM p_day);
  v_day := EXTRACT(DAY FROM p_day);

  -- Fixed-date Swedish public holidays.
  IF (v_month = 1 AND v_day IN (1, 6))
      OR (v_month = 5 AND v_day = 1)
      OR (v_month = 6 AND v_day = 6)
      OR (v_month = 12 AND v_day IN (25, 26)) THEN
    RETURN TRUE;
  END IF;

  -- Gregorian computus for Easter Sunday.
  a := MOD(v_year, 19);
  b := v_year / 100;
  c := MOD(v_year, 100);
  d := b / 4;
  e := MOD(b, 4);
  f := (b + 8) / 25;
  g := (b - f + 1) / 3;
  h := MOD(19 * a + b - d - g + 15, 30);
  i := c / 4;
  k := MOD(c, 4);
  l := MOD(32 + 2 * e + 2 * i - h - k, 7);
  m := (a + 11 * h + 22 * l) / 451;
  easter_month := (h + l - 7 * m + 114) / 31;
  easter_day := MOD(h + l - 7 * m + 114, 31) + 1;
  easter_sunday := MAKE_DATE(v_year, easter_month, easter_day);

  IF p_day = easter_sunday - 2
      OR p_day = easter_sunday
      OR p_day = easter_sunday + 1
      OR p_day = easter_sunday + 39
      OR p_day = easter_sunday + 49 THEN
    RETURN TRUE;
  END IF;

  -- Midsummer Day: Saturday between Jun 20-26.
  midsummer_day := MAKE_DATE(v_year, 6, 20);
  WHILE EXTRACT(ISODOW FROM midsummer_day) <> 6 LOOP
    midsummer_day := midsummer_day + 1;
  END LOOP;
  IF p_day = midsummer_day THEN
    RETURN TRUE;
  END IF;

  -- All Saints' Day: Saturday between Oct 31-Nov 6.
  all_saints_day := MAKE_DATE(v_year, 10, 31);
  WHILE EXTRACT(ISODOW FROM all_saints_day) <> 6 LOOP
    all_saints_day := all_saints_day + 1;
  END LOOP;
  IF p_day = all_saints_day THEN
    RETURN TRUE;
  END IF;

  RETURN FALSE;
END;
$$;

CREATE OR REPLACE FUNCTION public.planned_minutes_for_day(
  p_user_id uuid,
  p_day date
)
RETURNS integer
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_contract_percent integer := 100;
  v_full_time_hours integer := 40;
  v_weekly_target_minutes integer := 2400;
  v_iso_weekday integer;
  v_workday_index integer;
  v_base integer;
  v_remainder integer;
  v_base_scheduled integer;
  v_red_day_kind text;
  v_is_official_holiday boolean := FALSE;
BEGIN
  IF p_user_id IS NULL OR p_day IS NULL THEN
    RETURN 0;
  END IF;

  IF auth.uid() IS NULL OR p_user_id <> auth.uid() THEN
    RAISE EXCEPTION 'forbidden' USING ERRCODE = '42501';
  END IF;

  SELECT
    COALESCE(contract_percent, 100),
    COALESCE(full_time_hours, 40)
  INTO
    v_contract_percent,
    v_full_time_hours
  FROM profiles
  WHERE id = p_user_id;

  v_weekly_target_minutes :=
    ROUND((v_full_time_hours * 60.0 * v_contract_percent) / 100.0);

  -- ISO weekday: Mon=1 ... Sun=7
  v_iso_weekday := EXTRACT(ISODOW FROM p_day);
  IF v_iso_weekday < 1 OR v_iso_weekday > 5 THEN
    RETURN 0;
  END IF;

  -- Match TargetHoursCalculator deterministic weekday distribution.
  v_base := v_weekly_target_minutes / 5;
  v_remainder := MOD(v_weekly_target_minutes, 5);
  v_workday_index := v_iso_weekday - 1;
  v_base_scheduled := v_base + CASE
    WHEN v_workday_index < v_remainder THEN 1
    ELSE 0
  END;

  SELECT urd.kind
  INTO v_red_day_kind
  FROM user_red_days urd
  WHERE urd.user_id = p_user_id
    AND urd.date = p_day
  LIMIT 1;

  v_is_official_holiday := public.is_swedish_public_holiday(p_day);

  IF v_red_day_kind = 'FULL' OR v_is_official_holiday THEN
    RETURN 0;
  END IF;

  IF v_red_day_kind = 'HALF' THEN
    RETURN ROUND(v_base_scheduled * 0.5);
  END IF;

  RETURN v_base_scheduled;
END;
$$;

CREATE OR REPLACE FUNCTION public.get_time_balance_aggregates(
  p_user_id uuid,
  p_start_date date,
  p_end_date date,
  p_tracking_start_date date,
  p_travel_enabled boolean
)
RETURNS TABLE(
  day date,
  work_minutes integer,
  travel_minutes integer,
  credited_leave_minutes integer,
  credited_leave_by_type jsonb,
  planned_minutes integer,
  adjustment_minutes integer,
  delta_minutes integer,
  is_total boolean
)
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  v_start date;
  v_end date;
BEGIN
  IF auth.uid() IS NULL OR p_user_id <> auth.uid() THEN
    RAISE EXCEPTION 'forbidden' USING ERRCODE = '42501';
  END IF;

  v_start := GREATEST(
    COALESCE(p_start_date, CURRENT_DATE),
    COALESCE(p_tracking_start_date, p_start_date, CURRENT_DATE)
  );
  v_end := COALESCE(p_end_date, v_start);

  IF v_end < v_start THEN
    RETURN QUERY
    SELECT
      NULL::date AS day,
      0::integer AS work_minutes,
      0::integer AS travel_minutes,
      0::integer AS credited_leave_minutes,
      '{}'::jsonb AS credited_leave_by_type,
      0::integer AS planned_minutes,
      0::integer AS adjustment_minutes,
      0::integer AS delta_minutes,
      TRUE AS is_total;
    RETURN;
  END IF;

  RETURN QUERY
  WITH days AS (
    SELECT gs::date AS day
    FROM generate_series(v_start, v_end, '1 day'::interval) gs
  ),
  scoped_entries AS (
    SELECT
      e.id,
      e.type,
      e.date::date AS day,
      COALESCE(e.travel_minutes, 0) AS legacy_travel_minutes
    FROM entries e
    WHERE e.user_id = p_user_id
      AND e.date::date >= v_start
      AND e.date::date <= v_end
  ),
  work_minutes_by_entry AS (
    SELECT
      ws.entry_id,
      SUM(
        GREATEST(
          0,
          (EXTRACT(EPOCH FROM (ws.end_time - ws.start_time)) / 60)::integer
          - COALESCE(ws.unpaid_break_minutes, 0)
        )
      )::integer AS work_minutes
    FROM work_shifts ws
    JOIN scoped_entries se ON se.id = ws.entry_id
    GROUP BY ws.entry_id
  ),
  travel_minutes_by_entry AS (
    SELECT
      ts.entry_id,
      SUM(COALESCE(ts.travel_minutes, 0))::integer AS travel_minutes
    FROM travel_segments ts
    JOIN scoped_entries se ON se.id = ts.entry_id
    GROUP BY ts.entry_id
  ),
  entry_daily AS (
    SELECT
      se.day,
      SUM(
        CASE
          WHEN se.type = 'work' THEN COALESCE(wbe.work_minutes, 0)
          ELSE 0
        END
      )::integer AS work_minutes,
      SUM(
        CASE
          WHEN se.type = 'travel'
            THEN COALESCE(tbe.travel_minutes, se.legacy_travel_minutes, 0)
          ELSE 0
        END
      )::integer AS travel_minutes_raw
    FROM scoped_entries se
    LEFT JOIN work_minutes_by_entry wbe ON wbe.entry_id = se.id
    LEFT JOIN travel_minutes_by_entry tbe ON tbe.entry_id = se.id
    GROUP BY se.day
  ),
  planned_daily AS (
    SELECT
      d.day,
      planned_minutes_for_day(p_user_id, d.day) AS planned_minutes
    FROM days d
  ),
  adjustment_daily AS (
    SELECT
      ba.effective_date::date AS day,
      SUM(COALESCE(ba.delta_minutes, 0))::integer AS adjustment_minutes
    FROM balance_adjustments ba
    WHERE ba.user_id = p_user_id
      AND ba.effective_date >= v_start
      AND ba.effective_date <= v_end
    GROUP BY ba.effective_date::date
  ),
  paid_absence_rows AS (
    SELECT
      a.id,
      a.date::date AS day,
      a.type,
      COALESCE(a.minutes, 0) AS minutes
    FROM absences a
    WHERE a.user_id = p_user_id
      AND a.date >= v_start
      AND a.date <= v_end
      AND COALESCE(a.type, '') NOT IN ('unpaid', 'unknown')
  ),
  requested_leave AS (
    SELECT
      pa.id,
      pa.day,
      pa.type,
      pd.planned_minutes,
      CASE
        WHEN pa.minutes = 0 THEN pd.planned_minutes
        ELSE LEAST(pa.minutes, pd.planned_minutes)
      END::integer AS requested_credit
    FROM paid_absence_rows pa
    JOIN planned_daily pd ON pd.day = pa.day
  ),
  allocated_leave AS (
    SELECT
      rl.day,
      rl.type,
      GREATEST(
        LEAST(
          rl.requested_credit,
          rl.planned_minutes
          - COALESCE(
              SUM(rl.requested_credit) OVER (
                PARTITION BY rl.day
                ORDER BY rl.type, rl.id
                ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING
              ),
              0
            )
        ),
        0
      )::integer AS credited_minutes
    FROM requested_leave rl
  ),
  credited_daily AS (
    SELECT
      al.day,
      SUM(al.credited_minutes)::integer AS credited_leave_minutes
    FROM allocated_leave al
    GROUP BY al.day
  ),
  credited_by_type_daily AS (
    SELECT
      x.day,
      COALESCE(jsonb_object_agg(x.type, x.minutes), '{}'::jsonb)
        AS credited_leave_by_type
    FROM (
      SELECT
        al.day,
        al.type,
        SUM(al.credited_minutes)::integer AS minutes
      FROM allocated_leave al
      WHERE al.credited_minutes > 0
      GROUP BY al.day, al.type
      ORDER BY al.day, al.type
    ) x
    GROUP BY x.day
  ),
  daily_rows AS (
    SELECT
      d.day,
      COALESCE(ed.work_minutes, 0)::integer AS work_minutes,
      CASE
        WHEN COALESCE(p_travel_enabled, TRUE)
          THEN COALESCE(ed.travel_minutes_raw, 0)
        ELSE 0
      END::integer AS travel_minutes,
      COALESCE(cd.credited_leave_minutes, 0)::integer AS credited_leave_minutes,
      COALESCE(cbt.credited_leave_by_type, '{}'::jsonb) AS credited_leave_by_type,
      COALESCE(pd.planned_minutes, 0)::integer AS planned_minutes,
      COALESCE(ad.adjustment_minutes, 0)::integer AS adjustment_minutes,
      (
        COALESCE(ed.work_minutes, 0)
        + CASE
            WHEN COALESCE(p_travel_enabled, TRUE)
              THEN COALESCE(ed.travel_minutes_raw, 0)
            ELSE 0
          END
        + COALESCE(cd.credited_leave_minutes, 0)
        + COALESCE(ad.adjustment_minutes, 0)
        - COALESCE(pd.planned_minutes, 0)
      )::integer AS delta_minutes,
      FALSE AS is_total
    FROM days d
    LEFT JOIN entry_daily ed ON ed.day = d.day
    LEFT JOIN credited_daily cd ON cd.day = d.day
    LEFT JOIN credited_by_type_daily cbt ON cbt.day = d.day
    LEFT JOIN planned_daily pd ON pd.day = d.day
    LEFT JOIN adjustment_daily ad ON ad.day = d.day
  ),
  by_type_totals AS (
    SELECT
      COALESCE(
        jsonb_object_agg(t.key, t.total_minutes),
        '{}'::jsonb
      ) AS totals_json
    FROM (
      SELECT
        kv.key,
        SUM((kv.value)::integer)::integer AS total_minutes
      FROM daily_rows dr
      CROSS JOIN LATERAL jsonb_each_text(dr.credited_leave_by_type) kv
      GROUP BY kv.key
    ) t
  )
  SELECT
    dr.day,
    dr.work_minutes,
    dr.travel_minutes,
    dr.credited_leave_minutes,
    dr.credited_leave_by_type,
    dr.planned_minutes,
    dr.adjustment_minutes,
    dr.delta_minutes,
    dr.is_total
  FROM daily_rows dr

  UNION ALL

  SELECT
    NULL::date AS day,
    COALESCE(SUM(dr.work_minutes), 0)::integer AS work_minutes,
    COALESCE(SUM(dr.travel_minutes), 0)::integer AS travel_minutes,
    COALESCE(SUM(dr.credited_leave_minutes), 0)::integer AS credited_leave_minutes,
    COALESCE((SELECT totals_json FROM by_type_totals), '{}'::jsonb)
      AS credited_leave_by_type,
    COALESCE(SUM(dr.planned_minutes), 0)::integer AS planned_minutes,
    COALESCE(SUM(dr.adjustment_minutes), 0)::integer AS adjustment_minutes,
    COALESCE(SUM(dr.delta_minutes), 0)::integer AS delta_minutes,
    TRUE AS is_total
  FROM daily_rows dr
  ORDER BY is_total, day NULLS LAST;
END;
$$;
