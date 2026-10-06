ALTER TABLE team_invitation DROP CONSTRAINT team_invitation_status_check;
ALTER TABLE team_invitation ADD CONSTRAINT team_invitation_status_check
 CHECK(status IN ('PENDING','ACCEPTED','REVOKED','EXPIRED'));
UPDATE team_invitation SET status='EXPIRED'
 WHERE status='PENDING' AND expires_at<=now();
