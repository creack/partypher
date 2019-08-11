-- +goose Up
-- +goose StatementBegin

CREATE TABLE parts (
  part_id UUID NOT NULL PRIMARY KEY,

  part_name VARCHAR NOT NULL,

  created_at TIMESTAMP WITH TIME ZONE NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE NOT NULL,
  deleted_at TIMESTAMP WITH TIME ZONE
);

-- +goose StatementEnd

-- +goose Down
-- +goose StatementBegin

-- +goose StatementEnd
