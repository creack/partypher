package main

import (
	"context"
	"fmt"
	"os"
	"time"

	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"

	_ "github.com/lib/pq" // Load the postgres driver.
)

// TimeMetadata is the common time metadata fields for all components.
type TimeMetadata struct {
	CreatedAt time.Time `db:"created_at"`
	UpdatedAt time.Time `db:"updated_at"`
	DeletedAt time.Time `db:"deleted_at"`
}

// Tag .
type Tag struct {
	ID   uuid.UUID
	Name string
	TimeMetadata
}

// // Location represents where part is stored.
// type Location struct {
// 	ID uuid.UUID

// 	Name string
// }

// Part .
type Part struct {
	ID   uuid.UUID `db:"part_id"`
	Name string    `db:"part_name"`

	// Quantity int
	// Location Location

	//	Tags []Tag

	TimeMetadata
}

var _ Part

func main() {
	ctx := context.Background()
	db, err := sqlx.ConnectContext(ctx, "postgres", os.Getenv("PG_DSN"))
	if err != nil {
		panic(err)
	}

	p := Part{ID: uuid.New(), Name: "boilerplate part!!"}
	if _, err := db.NamedExecContext(ctx, `
INSERT INTO parts
(part_id, part_name, created_at, updated_at, deleted_at) VALUES
(:part_id, :part_name, :created_at, :updated_at, :deleted_at)
`, p); err != nil {
		panic(err)
	}

	var p2 Part
	if err := db.GetContext(ctx, &p2, db.Rebind("SELECT * FROM parts WHERE part_id = ? LIMIT 1"), p.ID); err != nil {
		panic(err)
	}

	fmt.Printf("hello world!-->\n%s\n", p2.Name)
}
