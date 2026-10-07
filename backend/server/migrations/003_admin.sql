CREATE FUNCTION admin.resolve_issue(p_project text, p_environment text, p_issue bigint)
RETURNS void
LANGUAGE sql
AS $$
  UPDATE issue
  SET state = 'resolved', resolved_at = now(), resolved_build = last_build
  FROM project
  WHERE project.id = issue.project_id
    AND project.slug = p_project
    AND project.environment = p_environment
    AND issue.id = p_issue;
$$;

CREATE FUNCTION admin.ignore_issue(p_project text, p_environment text, p_issue bigint)
RETURNS void
LANGUAGE sql
AS $$
  UPDATE issue
  SET state = 'ignored'
  FROM project
  WHERE project.id = issue.project_id
    AND project.slug = p_project
    AND project.environment = p_environment
    AND issue.id = p_issue;
$$;

CREATE FUNCTION admin.reopen_issue(p_project text, p_environment text, p_issue bigint)
RETURNS void
LANGUAGE sql
AS $$
  UPDATE issue
  SET state = 'open', resolved_at = NULL, resolved_build = NULL
  FROM project
  WHERE project.id = issue.project_id
    AND project.slug = p_project
    AND project.environment = p_environment
    AND issue.id = p_issue;
$$;

CREATE FUNCTION admin.delete_person(p_project text, p_environment text, p_user_id text)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  v_project integer;
  v_person bigint;
BEGIN
  SELECT id INTO v_project FROM project WHERE slug = p_project AND environment = p_environment;
  IF v_project IS NULL THEN
    RAISE EXCEPTION 'unknown project %/%', p_project, p_environment;
  END IF;
  SELECT id INTO v_person FROM person WHERE project_id = v_project AND user_id = p_user_id;
  IF v_person IS NULL THEN
    RAISE EXCEPTION 'unknown person %', p_user_id;
  END IF;
  DELETE FROM event WHERE project_id = v_project AND person_id = v_person;
  DELETE FROM crash WHERE project_id = v_project AND person_id = v_person;
  DELETE FROM session WHERE project_id = v_project AND person_id = v_person;
  DELETE FROM consent WHERE project_id = v_project AND person_id = v_person;
  UPDATE device SET person_id = NULL WHERE project_id = v_project AND person_id = v_person;
  DELETE FROM person WHERE id = v_person;
  INSERT INTO erasure (project_id, id, device_id, person_id, requested_at, completed_at)
  VALUES (v_project, gen_random_uuid(), '', v_person, now(), now());
END
$$;
