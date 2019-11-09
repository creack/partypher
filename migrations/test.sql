-- +goose Up
-- +goose StatementBegin

--SELECT * FROM v_parts_names;
--UPDATE v_parts_names SET part_name = 'LED2' WHERE part_name = 'LED1';
--SELECT * FROM v_parts_names;
--DELETE FROM v_parts_names WHERE lang_code = 'fr_FR';
--SELECT * FROM v_parts_names;

--WITH q AS (
--  INSERT INTO parts (created_by, updated_by) VALUES (root_id(), root_id()) RETURNING part_id
--) INSERT INTO parts_names (part_id, lang_code, created_by, updated_by, part_name) VALUES ((SELECT part_id FROM q), 'en_US', root_id(), root_id(), '74LS00');

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin

-- +goose StatementEnd
