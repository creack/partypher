package main

import (
	"context"
	"os"

	"github.com/jmoiron/sqlx"

	_ "github.com/lib/pq" // Load the postgres driver.
)

func main() {
	db, err := sqlx.Connect("postgres", os.Getenv("PG_ROOT_DSN"))
	if err != nil {
		panic(err)
	}
	var now string
	if err := db.GetContext(context.Background(), &now, "SELECT NOW()"); err != nil {
		panic(err)
	}

	println("hello world!", now)
}
