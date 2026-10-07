CREATE TABLE project (
  id serial PRIMARY KEY,
  slug text NOT NULL,
  environment text NOT NULL,
  UNIQUE (slug, environment)
);

CREATE TABLE person (
  id bigserial PRIMARY KEY,
  project_id integer NOT NULL REFERENCES project (id),
  user_id text NOT NULL,
  properties jsonb NOT NULL DEFAULT '{}'::jsonb,
  first_seen timestamptz NOT NULL,
  last_seen timestamptz NOT NULL,
  UNIQUE (project_id, user_id)
);

CREATE TABLE device (
  project_id integer NOT NULL REFERENCES project (id),
  id text NOT NULL,
  person_id bigint REFERENCES person (id) ON DELETE SET NULL,
  first_seen timestamptz NOT NULL,
  last_seen timestamptz NOT NULL,
  PRIMARY KEY (project_id, id)
);

CREATE INDEX device_person ON device (project_id, person_id);

CREATE TABLE ingested (
  project_id integer NOT NULL,
  id uuid NOT NULL,
  received_at timestamptz NOT NULL,
  PRIMARY KEY (project_id, id)
);

CREATE INDEX ingested_received ON ingested (received_at);

CREATE TABLE event (
  project_id integer NOT NULL,
  id uuid NOT NULL,
  time timestamptz NOT NULL,
  client_time timestamptz NOT NULL,
  received_at timestamptz NOT NULL,
  device_id text NOT NULL,
  person_id bigint,
  session_id text NOT NULL,
  name text NOT NULL,
  properties jsonb NOT NULL,
  context jsonb NOT NULL,
  app_version text NOT NULL,
  app_build text NOT NULL,
  platform text NOT NULL
) PARTITION BY RANGE (time);

CREATE TABLE event_default PARTITION OF event DEFAULT;

CREATE INDEX event_project_time ON event (project_id, time);
CREATE INDEX event_project_name_time ON event (project_id, name, time);
CREATE INDEX event_person ON event (project_id, person_id);
CREATE INDEX event_device ON event (project_id, device_id);
CREATE INDEX event_session ON event (project_id, session_id);

CREATE TABLE session (
  project_id integer NOT NULL,
  id text NOT NULL,
  device_id text NOT NULL,
  person_id bigint,
  started_at timestamptz NOT NULL,
  last_seen_at timestamptz NOT NULL,
  crashed boolean NOT NULL DEFAULT false,
  app_version text NOT NULL,
  platform text NOT NULL,
  PRIMARY KEY (project_id, id)
);

CREATE INDEX session_started ON session (project_id, started_at);
CREATE INDEX session_person ON session (project_id, person_id);
CREATE INDEX session_device ON session (project_id, device_id);

CREATE TABLE issue (
  id bigserial PRIMARY KEY,
  project_id integer NOT NULL REFERENCES project (id),
  fingerprint text NOT NULL,
  title text NOT NULL,
  exception_type text NOT NULL,
  state text NOT NULL DEFAULT 'open',
  first_seen timestamptz NOT NULL,
  last_seen timestamptz NOT NULL,
  first_build text NOT NULL,
  last_build text NOT NULL,
  resolved_at timestamptz,
  resolved_build text,
  regressed_at timestamptz,
  UNIQUE (project_id, fingerprint)
);

CREATE TABLE crash (
  project_id integer NOT NULL,
  id uuid NOT NULL,
  issue_id bigint NOT NULL,
  time timestamptz NOT NULL,
  client_time timestamptz NOT NULL,
  received_at timestamptz NOT NULL,
  device_id text NOT NULL,
  person_id bigint,
  session_id text NOT NULL,
  exception_type text NOT NULL,
  message text NOT NULL,
  frames jsonb NOT NULL,
  raw_stack_trace text NOT NULL,
  fatal boolean NOT NULL,
  thread text NOT NULL,
  custom_keys jsonb NOT NULL,
  logs jsonb NOT NULL,
  context jsonb NOT NULL,
  app_version text NOT NULL,
  app_build text NOT NULL,
  platform text NOT NULL
) PARTITION BY RANGE (time);

CREATE TABLE crash_default PARTITION OF crash DEFAULT;

CREATE INDEX crash_project_time ON crash (project_id, time);
CREATE INDEX crash_issue ON crash (project_id, issue_id, time);
CREATE INDEX crash_person ON crash (project_id, person_id);
CREATE INDEX crash_device ON crash (project_id, device_id);
CREATE INDEX crash_session ON crash (project_id, session_id);

CREATE TABLE consent (
  project_id integer NOT NULL,
  id uuid NOT NULL,
  device_id text NOT NULL,
  person_id bigint,
  purpose text NOT NULL,
  state text NOT NULL,
  policy_version text NOT NULL,
  time timestamptz NOT NULL,
  received_at timestamptz NOT NULL,
  PRIMARY KEY (project_id, id)
);

CREATE INDEX consent_device ON consent (project_id, device_id, time);

CREATE TABLE erasure (
  project_id integer NOT NULL,
  id uuid NOT NULL,
  device_id text NOT NULL,
  person_id bigint,
  requested_at timestamptz NOT NULL,
  completed_at timestamptz NOT NULL,
  PRIMARY KEY (project_id, id)
);

CREATE SCHEMA reporting;
CREATE SCHEMA admin;
