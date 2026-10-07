CREATE FUNCTION reporting.funnel_progress(step_count integer, masks bigint[], times timestamptz[], window_length interval, until timestamptz)
RETURNS integer
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
  best integer := 0;
  current integer := 0;
  entered timestamptz;
  i integer;
BEGIN
  IF masks IS NULL THEN
    RETURN 0;
  END IF;
  FOR i IN 1..array_length(masks, 1) LOOP
    IF current > 0 AND current < step_count AND (masks[i] & (1::bigint << current)) <> 0 AND times[i] <= entered + window_length THEN
      current := current + 1;
    ELSIF (masks[i] & 1) <> 0 AND (current = 0 OR times[i] > entered + window_length) AND times[i] < until THEN
      current := 1;
      entered := times[i];
    END IF;
    IF current > best THEN
      best := current;
    END IF;
  END LOOP;
  RETURN best;
END
$$;

CREATE FUNCTION reporting.funnel_steps(p_project text, p_environment text, p_steps jsonb, p_window interval, p_from timestamptz, p_to timestamptz)
RETURNS TABLE (step integer, name text, people bigint)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  WITH steps AS (
    SELECT ordinality::integer AS step,
           value ->> 'event' AS event,
           COALESCE(value -> 'filters', '{}'::jsonb) AS filters,
           COALESCE(NULLIF(value ->> 'label', ''), value ->> 'event') AS name
    FROM jsonb_array_elements(p_steps) WITH ORDINALITY
  ),
  matched AS (
    SELECT COALESCE(event.person_id::text, 'd:' || event.device_id) AS who, event.time,
           sum(1::bigint << (steps.step - 1))::bigint AS mask
    FROM event
    JOIN project ON project.id = event.project_id
    JOIN steps ON steps.event = event.name AND event.properties @> steps.filters
    WHERE project.slug = p_project
      AND project.environment = p_environment
      AND event.time >= p_from
      AND event.time < p_to + p_window
    GROUP BY 1, event.id, event.time
  ),
  reached AS (
    SELECT reporting.funnel_progress((SELECT count(*)::integer FROM steps), array_agg(matched.mask ORDER BY matched.time), array_agg(matched.time ORDER BY matched.time), p_window, p_to) AS best
    FROM matched
    GROUP BY matched.who
  )
  SELECT steps.step, steps.name, count(reached.best) FILTER (WHERE reached.best >= steps.step) AS people
  FROM steps
  LEFT JOIN reached ON true
  GROUP BY steps.step, steps.name
  ORDER BY steps.step;
$$;

CREATE FUNCTION reporting.retention_matching(p_project text, p_environment text, p_birth jsonb, p_return jsonb, p_period text, p_from timestamptz, p_to timestamptz, p_periods integer)
RETURNS TABLE (cohort timestamptz, period integer, cohort_size bigint, retained bigint)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  WITH scoped AS (
    SELECT COALESCE(event.person_id::text, 'd:' || event.device_id) AS who, event.time,
           (event.name = p_birth ->> 'event' AND event.properties @> COALESCE(p_birth -> 'filters', '{}'::jsonb)) AS born,
           (event.name = p_return ->> 'event' AND event.properties @> COALESCE(p_return -> 'filters', '{}'::jsonb)) AS returned
    FROM event
    JOIN project ON project.id = event.project_id
    WHERE project.slug = p_project
      AND project.environment = p_environment
      AND event.time >= p_from
      AND event.name IN (p_birth ->> 'event', p_return ->> 'event')
  ),
  birth AS (
    SELECT who, date_trunc(p_period, min(time)) AS cohort
    FROM scoped
    WHERE born AND time < p_to
    GROUP BY who
  ),
  sizes AS (
    SELECT cohort, count(*) AS cohort_size FROM birth GROUP BY cohort
  ),
  activity AS (
    SELECT DISTINCT birth.cohort, birth.who,
      CASE p_period
        WHEN 'day' THEN (date_trunc('day', scoped.time)::date - birth.cohort::date)
        WHEN 'week' THEN (date_trunc('week', scoped.time)::date - birth.cohort::date) / 7
        ELSE (extract(year FROM scoped.time) * 12 + extract(month FROM scoped.time) - extract(year FROM birth.cohort) * 12 - extract(month FROM birth.cohort))::integer
      END AS period
    FROM birth
    JOIN scoped ON scoped.who = birth.who AND scoped.returned AND scoped.time >= birth.cohort
  )
  SELECT sizes.cohort, periods.period, sizes.cohort_size, count(activity.who) AS retained
  FROM sizes
  CROSS JOIN generate_series(0, p_periods) AS periods (period)
  LEFT JOIN activity ON activity.cohort = sizes.cohort AND activity.period = periods.period
  GROUP BY sizes.cohort, periods.period, sizes.cohort_size
  ORDER BY sizes.cohort, periods.period;
$$;

CREATE FUNCTION admin.triage(p_project text, p_environment text, p_issue bigint, p_state text)
RETURNS boolean
LANGUAGE plpgsql
AS $$
DECLARE
  touched integer;
BEGIN
  IF p_state NOT IN ('open', 'resolved', 'ignored') THEN
    RAISE EXCEPTION 'unknown state %', p_state;
  END IF;
  UPDATE issue
  SET state = p_state,
      resolved_at = CASE WHEN p_state = 'resolved' THEN now() ELSE NULL END,
      resolved_build = CASE WHEN p_state = 'resolved' THEN last_build ELSE NULL END
  FROM project
  WHERE project.id = issue.project_id
    AND project.slug = p_project
    AND project.environment = p_environment
    AND issue.id = p_issue;
  GET DIAGNOSTICS touched = ROW_COUNT;
  RETURN touched > 0;
END
$$;
