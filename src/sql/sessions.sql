DROP TABLE IF EXISTS sessions;

-- セッションテーブル
CREATE TABLE sessions (
	id CHAR(32) NOT NULL PRIMARY KEY,
	a_session BYTEA NOT NULL,
	created_at TIMESTAMP NOT NULL DEFAULT now()
);
