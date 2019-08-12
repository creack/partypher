package db_test

import (
	"context"
	"os"
	"testing"

	"github.com/creack/partypher/db"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/stretchr/testify/require"
)

func newTestDB(t *testing.T) *sqlx.DB {
	t.Helper()

	ctx := context.Background()

	db, err := sqlx.ConnectContext(ctx, "postgres", os.Getenv("PG_DSN"))
	require.NoError(t, err, "Error connecting to the test database.")

	return db
}

func deletePart(dbx *sqlx.DB, partID uuid.UUID) {
	_, _ = dbx.ExecContext(context.Background(), dbx.Rebind(`DELETE FROM parts WHERE part_id = ?`), partID) // Best effort.
}

func newPart() db.Part {
	return db.Part{ID: uuid.New(), Name: "test_part_" + uuid.New().String()}
}

func TestInsertPart(t *testing.T) {
	ctx := context.Background()

	dbx := newTestDB(t)

	p := newPart()
	defer deletePart(dbx, p.ID)

	require.NoError(t, db.InsertPart(ctx, dbx, p), "Error inserting test part in db.")
}
