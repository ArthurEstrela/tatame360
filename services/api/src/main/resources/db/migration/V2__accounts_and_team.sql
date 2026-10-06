CREATE TABLE team_invitation (
 id uuid PRIMARY KEY,
 tenant_id uuid NOT NULL REFERENCES academy(id),
 unit_id uuid NOT NULL,
 email text NOT NULL,
 name text NOT NULL,
 role text NOT NULL CHECK(role IN ('MANAGER','INSTRUCTOR','FRONT_DESK')),
 token_hash text NOT NULL UNIQUE,
 status text NOT NULL DEFAULT 'PENDING' CHECK(status IN ('PENDING','ACCEPTED','REVOKED')),
 invited_by uuid NOT NULL REFERENCES app_user(id),
 accepted_by uuid REFERENCES app_user(id),
 expires_at timestamptz NOT NULL,
 created_at timestamptz NOT NULL DEFAULT now(),
 accepted_at timestamptz,
 FOREIGN KEY(tenant_id,unit_id) REFERENCES academy_unit(tenant_id,id)
);
CREATE UNIQUE INDEX team_invitation_pending
 ON team_invitation(tenant_id,lower(email)) WHERE status='PENDING';
CREATE INDEX team_invitation_token ON team_invitation(token_hash);

CREATE TABLE password_reset (
 id uuid PRIMARY KEY,
 user_id uuid NOT NULL REFERENCES app_user(id),
 token_hash text NOT NULL UNIQUE,
 expires_at timestamptz NOT NULL,
 consumed_at timestamptz,
 created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX password_reset_user ON password_reset(user_id,created_at DESC);
