CREATE TABLE symbol_build (
  id serial PRIMARY KEY,
  project text NOT NULL,
  build text NOT NULL,
  uploaded_at timestamptz NOT NULL,
  reported boolean NOT NULL DEFAULT false,
  UNIQUE (project, build)
);

CREATE TABLE symbol_kind (
  build_id integer NOT NULL REFERENCES symbol_build (id) ON DELETE CASCADE,
  kind text NOT NULL,
  directory text NOT NULL,
  files integer NOT NULL,
  PRIMARY KEY (build_id, kind)
);

CREATE TABLE symbol_entry (
  build_id integer NOT NULL,
  kind text NOT NULL,
  identifier text NOT NULL,
  path text NOT NULL,
  PRIMARY KEY (build_id, kind, identifier),
  FOREIGN KEY (build_id, kind) REFERENCES symbol_kind (build_id, kind) ON DELETE CASCADE
);

ALTER TABLE crash ADD COLUMN raw_frames jsonb;
UPDATE crash SET raw_frames = frames;
ALTER TABLE crash ALTER COLUMN raw_frames SET NOT NULL;

CREATE INDEX crash_build ON crash (project_id, app_build);

ALTER TABLE issue ADD COLUMN regrouped boolean NOT NULL DEFAULT false;

CREATE OR REPLACE VIEW reporting.issue AS
SELECT project.slug AS project, project.environment, issue.id AS issue_id, issue.title,
       issue.exception_type, issue.state, issue.first_seen, issue.last_seen, issue.first_build,
       issue.last_build, issue.resolved_at, issue.resolved_build, issue.regressed_at,
       (SELECT count(*) FROM crash WHERE crash.issue_id = issue.id) AS crashes,
       (SELECT count(DISTINCT COALESCE(crash.person_id::text, 'd:' || crash.device_id)) FROM crash WHERE crash.issue_id = issue.id) AS affected_users,
       issue.regrouped
FROM issue
JOIN project ON project.id = issue.project_id;

CREATE OR REPLACE VIEW reporting.crash AS
SELECT project.slug AS project, project.environment, crash.id, crash.issue_id, issue.title,
       crash.time, crash.received_at, crash.device_id, crash.person_id, person.user_id,
       crash.session_id, crash.exception_type, crash.message, crash.frames, crash.raw_stack_trace,
       crash.fatal, crash.thread, crash.custom_keys, crash.logs, crash.context,
       crash.app_version, crash.app_build, crash.platform, crash.raw_frames
FROM crash
JOIN project ON project.id = crash.project_id
JOIN issue ON issue.id = crash.issue_id
LEFT JOIN person ON person.id = crash.person_id;
