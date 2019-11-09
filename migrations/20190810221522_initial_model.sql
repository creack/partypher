-- +goose Up
-- +goose StatementBegin

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DROP TABLE IF EXISTS metadata CASCADE;
CREATE TABLE metadata (
  created_by UUID NOT NULL,
  updated_by UUID NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
  deleted_at TIMESTAMP WITH TIME ZONE NULL
);

DROP TABLE IF EXISTS users CASCADE;
CREATE TABLE users (
  user_id UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_name VARCHAR NOT NULL UNIQUE
) INHERITS (metadata);

DROP FUNCTION IF EXISTS root_id();
CREATE FUNCTION root_id() RETURNS UUID LANGUAGE SQL AS $$ SELECT '11111111-1111-1111-1111-111111111111'::UUID $$;

ALTER TABLE metadata ADD CONSTRAINT fk_created_by FOREIGN KEY (created_by) REFERENCES users (user_id);
ALTER TABLE metadata ADD CONSTRAINT fk_updated_by FOREIGN KEY (created_by) REFERENCES users (user_id);

DROP TABLE IF EXISTS langs CASCADE;
CREATE TABLE langs (
  lang_code VARCHAR NOT NULL PRIMARY KEY -- i.e. en-US, fr-FR, etc.
) INHERITS (metadata);

DROP TABLE IF EXISTS langs_name CASCADE;
CREATE TABLE langs_names (
  lang_code        VARCHAR NOT NULL REFERENCES langs (lang_code), -- Target language.
  lang_code_locale VARCHAR NOT NULL REFERENCES langs (lang_code), -- Display langauge.

  lang_name VARCHAR NOT NULL,

  PRIMARY KEY (lang_code, lang_code_locale)
) INHERITS (metadata);

DROP TABLE IF EXISTS parts CASCADE;
CREATE TABLE parts (
  part_id UUID NOT NULL PRIMARY KEY DEFAULT uuid_generate_v4()
) INHERITS (metadata);

DROP TABLE IF EXISTS parts_name CASCADE;
CREATE TABLE parts_names (
  part_id UUID NOT NULL REFERENCES parts (part_id),
  lang_code VARCHAR NOT NULL REFERENCES langs (lang_code),
  version INT NOT NULL DEFAULT 1,

  part_name VARCHAR NOT NULL,

  PRIMARY KEY (part_id, lang_code, version)
) INHERITS (metadata);


-- Seeds.
INSERT INTO users (user_id, user_name, created_by, updated_by) VALUES (root_id(), 'root', root_id(), root_id());

INSERT INTO langs (lang_code, created_by, updated_by) VALUES
  ('en_US', root_id(), root_id()),
  ('fr_FR', root_id(), root_id());
INSERT INTO langs_names (lang_code, lang_code_locale, lang_name, created_by, updated_by) VALUES
  ('en_US', 'en_US', 'english', root_id(), root_id()),
  ('fr_FR', 'en_US', 'french', root_id(), root_id()),
  ('en_US', 'fr_FR', 'anglais', root_id(), root_id()),
  ('fr_FR', 'fr_FR', 'français', root_id(), root_id());

WITH q AS (INSERT INTO parts (created_by, updated_by) VALUES (root_id(), root_id()) RETURNING part_id)
INSERT INTO parts_names (part_id, lang_code, version, part_name, created_by, updated_by) VALUES
  ((SELECT part_id FROM q), 'en_US', 1, 'LED0', root_id(), root_id()),
  ((SELECT part_id FROM q), 'fr_FR', 1, 'DEL0', root_id(), root_id());

WITH q AS (SELECT part_id FROM parts)
INSERT INTO parts_names (part_id, lang_code, version, part_name, created_by, updated_by) VALUES
  ((SELECT part_id FROM q), 'en_US', 2, 'LED1', root_id(), root_id()),
  ((SELECT part_id FROM q), 'fr_FR', 2, 'DEL1', root_id(), root_id());

WITH q AS (SELECT part_id FROM parts)
INSERT INTO parts_names (part_id, lang_code, version, part_name, created_by, updated_by) VALUES
  ((SELECT part_id FROM q), 'fr_FR', 3, 'DEL2', root_id(), root_id());


--SELECT part_id, version, lang_code, (SELECT lang_name FROM langs_names WHERE lang_code = pn.lang_code AND lang_code_locale = 'fr_FR'), part_name FROM parts p LEFT JOIN parts_names pn USING (part_id);

--WITH cte AS (
--SELECT cs.*, row_number() OVER (partition BY c.customer_id ORDER BY sequence DESC) rn
--FROM customer c JOIN customer_settings cs ON c.customerid=cs.customerid
--) SELECT * FROM cte WHERE rn=1

DROP VIEW IF EXISTS v_parts_names;
CREATE VIEW v_parts_names AS
WITH cte AS (
  SELECT *, row_number() OVER (PARTITION BY part_id, lang_code ORDER BY version DESC) rn FROM parts_names
)
SELECT part_id, lang_code, version, part_name, created_by, updated_by, created_at, updated_at FROM cte WHERE rn = 1 AND deleted_at IS NULL;

DROP FUNCTION IF EXISTS proc_insert_parts_names();
CREATE FUNCTION proc_insert_parts_names()
  RETURNS trigger LANGUAGE PLPGSQL AS
$$
BEGIN
  INSERT INTO parts_names (part_id, lang_code, version, part_name, created_by, updated_by)
  VALUES (NEW.part_id, NEW.lang_code, 1, NEW.part_name, NEW.created_by, NEW.created_by);
  RETURN NEW;
END;
$$;
CREATE TRIGGER trig_insert_parts_names
  INSTEAD OF INSERT ON v_parts_names
  FOR EACH ROW
  EXECUTE PROCEDURE proc_insert_parts_names();

DROP FUNCTION IF EXISTS proc_update_parts_names();
CREATE FUNCTION proc_update_parts_names()
  RETURNS trigger LANGUAGE PLPGSQL AS
$$
BEGIN
  INSERT INTO parts_names (part_id, lang_code, version, part_name, created_by, updated_by)
  VALUES (NEW.part_id, NEW.lang_code, OLD.version + 1, NEW.part_name, OLD.created_by, NEW.updated_by);
  RETURN NEW;
END;
$$;
CREATE TRIGGER trig_update_parts_names
  INSTEAD OF UPDATE ON v_parts_names
  FOR EACH ROW
  EXECUTE PROCEDURE proc_update_parts_names();

DROP FUNCTION IF EXISTS proc_delete_parts_names();
CREATE FUNCTION proc_delete_parts_names()
  RETURNS trigger LANGUAGE PLPGSQL AS
$$
BEGIN
  INSERT INTO parts_names (part_id, lang_code, version, part_name, created_by, updated_by, deleted_at)
  VALUES (OLD.part_id, OLD.lang_code, OLD.version + 1, OLD.part_name, OLD.created_by, root_id(), NOW());
  RETURN NEW;
END;
$$;
CREATE TRIGGER trig_delete_parts_names
  INSTEAD OF DELETE ON v_parts_names
  FOR EACH ROW
  EXECUTE PROCEDURE proc_delete_parts_names();

DROP USER IF EXISTS jojo;
CREATE USER jojo;

--GRANT READ ON DATABASE partypher TO jojo;

GRANT INSERT ON parts TO jojo;
GRANT SELECT ON parts TO jojo;
GRANT INSERT ON parts_names TO jojo;
GRANT SELECT ON parts_names TO jojo;

GRANT ALL PRIVILEGES ON v_parts_names TO jojo;


--SELECT * FROM (SELECT *, row_number() OVER (PARTITION BY part_id, lang_code ORDER BY version DESC) rn FROM parts_names) q WHERE q.rn = 1;
--SELECT *, row_number() OVER (PARTITION BY part_id, lang_code ORDER BY version DESC) FROM parts_names WHERE rn = 1;
-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin

-- +goose StatementEnd
