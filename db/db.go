package db

import (
	"context"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/pkg/errors"

	_ "github.com/lib/pq" // Load the postgres driver.
)

// TimeMetadata is the common time metadata fields for all components.
type TimeMetadata struct {
	CreatedAt time.Time `db:"created_at"`
	UpdatedAt time.Time `db:"updated_at"`
	DeletedAt time.Time `db:"deleted_at"`
}

// Part is the db representation of an inventory part.
type Part struct {
	ID   uuid.UUID `db:"part_id"`
	Name string    `db:"part_name"`

	TimeMetadata
}

// InsertPart inserts the given part object into the database.
func InsertPart(ctx context.Context, db *sqlx.DB, p Part) error {
	var deletedAt *time.Time
	if !p.DeletedAt.IsZero() {
		deletedAt = &p.DeletedAt
	}
	if _, err := db.ExecContext(ctx, db.Rebind(`
INSERT INTO parts (
  part_id,
  part_name,
  created_at,
  updated_at,
  deleted_at
) VALUES (
  ?, -- part_id,
  ?, -- part_name,
  ?, -- created_at,
  ?, -- updated_at,
  ?  -- deleted_at
)`),
		p.ID,
		p.Name,
		p.CreatedAt,
		p.UpdatedAt,
		deletedAt); err != nil {
		return errors.Wrap(err, "db.Exec Insert")
	}
	return nil
}

// GetPart fetchdes an individual part from the db based on it's ID.
func GetPart(ctx context.Context, db *sqlx.DB, id uuid.UUID) (*Part, error) {
	const q = `
SELECT
  part_id,
  part_name,
  created_at,
  updated_at,
  COALESCE(deleted_at, '0001-01-01 00:00:00+00') AS deleted_at
FROM parts
WHERE part_id = ?`
	var p Part
	if err := db.GetContext(ctx, &p, db.Rebind(q), id); err != nil {
		return nil, errors.Wrap(err, "db.Get")
	}
	return &p, nil
}
