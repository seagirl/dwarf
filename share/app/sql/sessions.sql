DROP TABLE IF EXISTS sessions;

-- セッションテーブル
CREATE TABLE sessions (
	sid VARCHAR(32) NOT NULL PRIMARY KEY,
	data TEXT,
	expires INT NOT NULL,
	created_at TIMESTAMP NOT NULL DEFAULT now(),
	UNIQUE(sid)
);
