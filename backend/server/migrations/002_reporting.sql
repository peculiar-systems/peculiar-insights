CREATE VIEW reporting.event AS
SELECT project.slug AS project, project.environment, event.id, event.time, event.received_at,
       event.device_id, event.person_id, person.user_id, event.session_id, event.name,
       event.properties, event.context, event.app_version, event.app_build, event.platform
FROM event
JOIN project ON project.id = event.project_id
LEFT JOIN person ON person.id = event.person_id;

CREATE VIEW reporting.person AS
SELECT project.slug AS project, project.environment, person.id AS person_id, person.user_id,
       person.properties, person.first_seen, person.last_seen,
       (SELECT count(*) FROM device WHERE device.person_id = person.id) AS devices
FROM person
JOIN project ON project.id = person.project_id;

CREATE VIEW reporting.device AS
SELECT project.slug AS project, project.environment, device.id AS device_id, device.person_id,
       person.user_id, device.first_seen, device.last_seen
FROM device
JOIN project ON project.id = device.project_id
LEFT JOIN person ON person.id = device.person_id;

CREATE VIEW reporting.session AS
SELECT project.slug AS project, project.environment, session.id AS session_id, session.device_id,
       session.person_id, person.user_id, session.started_at, session.last_seen_at,
       session.last_seen_at - session.started_at AS duration, session.crashed,
       session.app_version, session.platform
FROM session
JOIN project ON project.id = session.project_id
LEFT JOIN person ON person.id = session.person_id;

CREATE VIEW reporting.issue AS
SELECT project.slug AS project, project.environment, issue.id AS issue_id, issue.title,
       issue.exception_type, issue.state, issue.first_seen, issue.last_seen, issue.first_build,
       issue.last_build, issue.resolved_at, issue.resolved_build, issue.regressed_at,
       (SELECT count(*) FROM crash WHERE crash.issue_id = issue.id) AS crashes,
       (SELECT count(DISTINCT COALESCE(crash.person_id::text, 'd:' || crash.device_id)) FROM crash WHERE crash.issue_id = issue.id) AS affected_users
FROM issue
JOIN project ON project.id = issue.project_id;

CREATE VIEW reporting.crash AS
SELECT project.slug AS project, project.environment, crash.id, crash.issue_id, issue.title,
       crash.time, crash.received_at, crash.device_id, crash.person_id, person.user_id,
       crash.session_id, crash.exception_type, crash.message, crash.frames, crash.raw_stack_trace,
       crash.fatal, crash.thread, crash.custom_keys, crash.logs, crash.context,
       crash.app_version, crash.app_build, crash.platform
FROM crash
JOIN project ON project.id = crash.project_id
JOIN issue ON issue.id = crash.issue_id
LEFT JOIN person ON person.id = crash.person_id;

CREATE VIEW reporting.consent AS
SELECT project.slug AS project, project.environment, consent.id, consent.device_id,
       consent.person_id, consent.purpose, consent.state, consent.policy_version,
       consent.time, consent.received_at
FROM consent
JOIN project ON project.id = consent.project_id;

CREATE VIEW reporting.erasure AS
SELECT project.slug AS project, project.environment, erasure.id, erasure.device_id,
       erasure.person_id, erasure.requested_at, erasure.completed_at
FROM erasure
JOIN project ON project.id = erasure.project_id;

CREATE VIEW reporting.crash_free_daily AS
SELECT project.slug AS project, project.environment, date_trunc('day', session.started_at) AS day,
       session.platform, session.app_version,
       count(*) AS sessions,
       count(*) FILTER (WHERE NOT session.crashed) AS crash_free_sessions,
       count(DISTINCT COALESCE(session.person_id::text, 'd:' || session.device_id)) AS users,
       count(DISTINCT COALESCE(session.person_id::text, 'd:' || session.device_id)) FILTER (WHERE NOT session.crashed) AS crash_free_users
FROM session
JOIN project ON project.id = session.project_id
GROUP BY 1, 2, 3, 4, 5;

CREATE FUNCTION reporting.funnel_reached(steps text[], names text[], times timestamptz[], window_length interval, until timestamptz)
RETURNS integer
LANGUAGE plpgsql IMMUTABLE
AS $$
DECLARE
  best integer := 0;
  current integer := 0;
  entered timestamptz;
  i integer;
BEGIN
  IF names IS NULL THEN
    RETURN 0;
  END IF;
  FOR i IN 1..array_length(names, 1) LOOP
    IF names[i] = steps[1] AND (current = 0 OR times[i] > entered + window_length) AND times[i] < until THEN
      current := 1;
      entered := times[i];
    ELSIF current > 0 AND current < array_length(steps, 1) AND names[i] = steps[current + 1] AND times[i] <= entered + window_length THEN
      current := current + 1;
    END IF;
    IF current > best THEN
      best := current;
    END IF;
  END LOOP;
  RETURN best;
END
$$;

CREATE FUNCTION reporting.funnel(p_project text, p_environment text, p_steps text[], p_window interval, p_from timestamptz, p_to timestamptz)
RETURNS TABLE (step integer, name text, people bigint)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  WITH reached AS (
    SELECT reporting.funnel_reached(p_steps, array_agg(event.name ORDER BY event.time), array_agg(event.time ORDER BY event.time), p_window, p_to) AS best
    FROM event
    JOIN project ON project.id = event.project_id
    WHERE project.slug = p_project
      AND project.environment = p_environment
      AND event.name = ANY (p_steps)
      AND event.time >= p_from
      AND event.time < p_to + p_window
    GROUP BY COALESCE(event.person_id::text, 'd:' || event.device_id)
  )
  SELECT steps.step, p_steps[steps.step] AS name, count(reached.best) FILTER (WHERE reached.best >= steps.step) AS people
  FROM generate_series(1, array_length(p_steps, 1)) AS steps (step)
  LEFT JOIN reached ON true
  GROUP BY steps.step
  ORDER BY steps.step;
$$;

CREATE FUNCTION reporting.retention(p_project text, p_environment text, p_birth text, p_return text, p_period text, p_from timestamptz, p_to timestamptz, p_periods integer)
RETURNS TABLE (cohort timestamptz, period integer, cohort_size bigint, retained bigint)
LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = public, pg_temp
AS $$
  WITH scoped AS (
    SELECT COALESCE(event.person_id::text, 'd:' || event.device_id) AS who, event.name, event.time
    FROM event
    JOIN project ON project.id = event.project_id
    WHERE project.slug = p_project
      AND project.environment = p_environment
      AND event.time >= p_from
      AND event.name IN (p_birth, p_return)
  ),
  birth AS (
    SELECT who, date_trunc(p_period, min(time)) AS cohort
    FROM scoped
    WHERE name = p_birth AND time < p_to
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
    JOIN scoped ON scoped.who = birth.who AND scoped.name = p_return AND scoped.time >= birth.cohort
  )
  SELECT sizes.cohort, periods.period, sizes.cohort_size, count(activity.who) AS retained
  FROM sizes
  CROSS JOIN generate_series(0, p_periods) AS periods (period)
  LEFT JOIN activity ON activity.cohort = sizes.cohort AND activity.period = periods.period
  GROUP BY sizes.cohort, periods.period, sizes.cohort_size
  ORDER BY sizes.cohort, periods.period;
$$;
