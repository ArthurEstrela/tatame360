CREATE TABLE app_user (
 id uuid PRIMARY KEY, email text NOT NULL UNIQUE, name text NOT NULL,
 password_hash text NOT NULL, active boolean NOT NULL DEFAULT true
);
CREATE TABLE academy (
 id uuid PRIMARY KEY, name text NOT NULL, timezone text NOT NULL DEFAULT 'America/Sao_Paulo',
 collection_started date NOT NULL DEFAULT CURRENT_DATE
);
CREATE TABLE academy_unit (
 id uuid PRIMARY KEY, tenant_id uuid NOT NULL REFERENCES academy(id), name text NOT NULL,
 UNIQUE(tenant_id,id)
);
CREATE TABLE role_assignment (
 id uuid PRIMARY KEY, tenant_id uuid NOT NULL REFERENCES academy(id),
 unit_id uuid NOT NULL, user_id uuid NOT NULL REFERENCES app_user(id),
 role text NOT NULL CHECK(role IN ('OWNER','MANAGER','INSTRUCTOR','FRONT_DESK','STUDENT','GUARDIAN')),
 active boolean NOT NULL DEFAULT true, UNIQUE(tenant_id,user_id),
 FOREIGN KEY(tenant_id,unit_id) REFERENCES academy_unit(tenant_id,id)
);
CREATE TABLE auth_session (
 id uuid PRIMARY KEY, user_id uuid NOT NULL REFERENCES app_user(id),
 access_hash text NOT NULL UNIQUE, refresh_hash text NOT NULL UNIQUE,
 access_expires timestamptz NOT NULL, refresh_expires timestamptz NOT NULL,
 revoked boolean NOT NULL DEFAULT false, family_id uuid NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE class_template (
 id uuid PRIMARY KEY, tenant_id uuid NOT NULL REFERENCES academy(id), unit_id uuid NOT NULL,
 name text NOT NULL, weekday integer NOT NULL CHECK(weekday BETWEEN 1 AND 7),
 local_time time NOT NULL, duration_minutes integer NOT NULL CHECK(duration_minutes BETWEEN 15 AND 240),
 instructor_id uuid NOT NULL REFERENCES app_user(id), active boolean NOT NULL DEFAULT true,
 UNIQUE(tenant_id,id), FOREIGN KEY(tenant_id,unit_id) REFERENCES academy_unit(tenant_id,id)
);
CREATE TABLE student (
 id uuid PRIMARY KEY, tenant_id uuid NOT NULL REFERENCES academy(id), unit_id uuid NOT NULL,
 name text NOT NULL, email text, phone text, birth_date date,
 belt text NOT NULL DEFAULT 'Branca', degrees integer NOT NULL DEFAULT 0 CHECK(degrees BETWEEN 0 AND 10),
 user_id uuid REFERENCES app_user(id), version integer NOT NULL DEFAULT 0,
 created_at timestamptz NOT NULL DEFAULT now(), UNIQUE(tenant_id,id),
 FOREIGN KEY(tenant_id,unit_id) REFERENCES academy_unit(tenant_id,id)
);
CREATE INDEX student_search ON student(tenant_id, name, id);
CREATE TABLE membership (
 id uuid PRIMARY KEY, tenant_id uuid NOT NULL, student_id uuid NOT NULL,
 starts_on date NOT NULL, ends_on date, status text NOT NULL CHECK(status IN ('ACTIVE','PAUSED','CANCELLED')),
 primary_class_id uuid, UNIQUE(tenant_id,id),
 FOREIGN KEY(tenant_id,student_id) REFERENCES student(tenant_id,id),
 FOREIGN KEY(tenant_id,primary_class_id) REFERENCES class_template(tenant_id,id),
 CHECK(ends_on IS NULL OR ends_on >= starts_on)
);
CREATE UNIQUE INDEX membership_current ON membership(tenant_id,student_id) WHERE status <> 'CANCELLED';
CREATE TABLE pause_period (
 id uuid PRIMARY KEY, tenant_id uuid NOT NULL, membership_id uuid NOT NULL,
 starts_on date NOT NULL, ends_on date NOT NULL, reason text NOT NULL,
 FOREIGN KEY(tenant_id,membership_id) REFERENCES membership(tenant_id,id), CHECK(ends_on >= starts_on)
);
CREATE TABLE class_session (
 id uuid PRIMARY KEY, tenant_id uuid NOT NULL, unit_id uuid NOT NULL, template_id uuid NOT NULL,
 starts_at timestamptz NOT NULL, ends_at timestamptz NOT NULL,
 status text NOT NULL DEFAULT 'SCHEDULED' CHECK(status IN ('SCHEDULED','IN_PROGRESS','COMPLETED','CANCELLED')),
 version integer NOT NULL DEFAULT 0, UNIQUE(tenant_id,id), UNIQUE(tenant_id,template_id,starts_at),
 FOREIGN KEY(tenant_id,template_id) REFERENCES class_template(tenant_id,id),
 FOREIGN KEY(tenant_id,unit_id) REFERENCES academy_unit(tenant_id,id), CHECK(ends_at > starts_at)
);
CREATE INDEX session_period ON class_session(tenant_id,starts_at);
CREATE TABLE session_roster (
 tenant_id uuid NOT NULL, session_id uuid NOT NULL, student_id uuid NOT NULL,
 PRIMARY KEY(tenant_id,session_id,student_id),
 FOREIGN KEY(tenant_id,session_id) REFERENCES class_session(tenant_id,id),
 FOREIGN KEY(tenant_id,student_id) REFERENCES student(tenant_id,id)
);
CREATE TABLE attendance (
 id uuid PRIMARY KEY, tenant_id uuid NOT NULL, session_id uuid NOT NULL, student_id uuid NOT NULL,
 author_id uuid NOT NULL REFERENCES app_user(id), source text NOT NULL CHECK(source IN ('MANUAL','QR','OFFLINE_SYNC')),
 valid boolean NOT NULL DEFAULT true, recorded_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(tenant_id,id), UNIQUE(tenant_id,session_id,student_id),
 FOREIGN KEY(tenant_id,session_id) REFERENCES class_session(tenant_id,id),
 FOREIGN KEY(tenant_id,student_id) REFERENCES student(tenant_id,id)
);
CREATE TABLE promotion_event (
 id uuid PRIMARY KEY, tenant_id uuid NOT NULL, student_id uuid NOT NULL,
 previous_belt text NOT NULL, previous_degrees integer NOT NULL, belt text NOT NULL, degrees integer NOT NULL,
 effective_on date NOT NULL, author_id uuid NOT NULL REFERENCES app_user(id), created_at timestamptz NOT NULL DEFAULT now(),
 FOREIGN KEY(tenant_id,student_id) REFERENCES student(tenant_id,id)
);
CREATE TABLE retention_snapshot (
 id uuid PRIMARY KEY, tenant_id uuid NOT NULL, membership_id uuid NOT NULL,
 evaluated_on date NOT NULL, rule_version integer NOT NULL DEFAULT 1, state text NOT NULL, score integer,
 factors jsonb NOT NULL, created_at timestamptz NOT NULL DEFAULT now(),
 UNIQUE(tenant_id,membership_id,evaluated_on,rule_version),
 FOREIGN KEY(tenant_id,membership_id) REFERENCES membership(tenant_id,id), CHECK(score BETWEEN 0 AND 100)
);
CREATE TABLE retention_alert (
 id uuid PRIMARY KEY, tenant_id uuid NOT NULL, membership_id uuid NOT NULL,
 status text NOT NULL DEFAULT 'OPEN' CHECK(status IN ('OPEN','IN_PROGRESS','SNOOZED','RETURN_OBSERVED','CLOSED')),
 reason text NOT NULL, score integer, owner_id uuid NOT NULL REFERENCES app_user(id), due_on date NOT NULL,
 opened_at timestamptz NOT NULL DEFAULT now(), returned_at timestamptz, closed_at timestamptz,
 close_reason text, version integer NOT NULL DEFAULT 0, UNIQUE(tenant_id,id),
 FOREIGN KEY(tenant_id,membership_id) REFERENCES membership(tenant_id,id)
);
CREATE UNIQUE INDEX alert_open ON retention_alert(tenant_id,membership_id) WHERE status <> 'CLOSED';
CREATE TABLE contact_event (
 id uuid PRIMARY KEY, tenant_id uuid NOT NULL, alert_id uuid NOT NULL,
 author_id uuid NOT NULL REFERENCES app_user(id), outcome text NOT NULL, note text NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(),
 FOREIGN KEY(tenant_id,alert_id) REFERENCES retention_alert(tenant_id,id)
);
CREATE TABLE import_batch (
 id uuid PRIMARY KEY, tenant_id uuid NOT NULL REFERENCES academy(id), author_id uuid NOT NULL REFERENCES app_user(id),
 rows_data jsonb NOT NULL, confirmed boolean NOT NULL DEFAULT false, created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE idempotency_record (
 tenant_id uuid NOT NULL REFERENCES academy(id), user_id uuid NOT NULL REFERENCES app_user(id),
 operation text NOT NULL, key uuid NOT NULL, payload_hash text NOT NULL, response jsonb NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(), PRIMARY KEY(tenant_id,user_id,operation,key)
);
CREATE TABLE audit_event (
 id uuid PRIMARY KEY, tenant_id uuid NOT NULL REFERENCES academy(id), author_id uuid REFERENCES app_user(id),
 action text NOT NULL, resource_id uuid NOT NULL, details jsonb NOT NULL DEFAULT '{}', created_at timestamptz NOT NULL DEFAULT now()
);
CREATE TABLE outbox_event (
 id uuid PRIMARY KEY, tenant_id uuid NOT NULL REFERENCES academy(id), event_type text NOT NULL,
 resource_id uuid NOT NULL, created_at timestamptz NOT NULL DEFAULT now(), processed_at timestamptz
);
