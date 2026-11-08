CREATE TABLE feedback (
  id TEXT PRIMARY KEY,
  created_at TEXT NOT NULL DEFAULT (strftime('%Y-%m-%dT%H:%M:%SZ', 'now')),
  reason TEXT NOT NULL CHECK(reason IN ('understand','compare','focus','curious','other')),
  use_case TEXT NOT NULL CHECK(use_case IN ('coding','research','writing','design','other')),
  wish TEXT NOT NULL DEFAULT '' CHECK(length(wish) <= 500),
  app_version TEXT NOT NULL,
  schema_version INTEGER NOT NULL CHECK(schema_version = 1)
);
CREATE INDEX feedback_created_at ON feedback(created_at);
