package main

import (
	"context"

	_ "github.com/go-sql-driver/mysql" // Load the mysql driver.
	"github.com/jmoiron/sqlx"
)

func main() {
	db, err := sqlx.Connect("mysql", "root:mySuperSecretPassword@tcp(localhost:3306)/mysql")
	if err != nil {
		panic(err)
	}
	var now string
	if err := db.GetContext(context.Background(), &now, "SELECT NOW()"); err != nil {
		panic(err)
	}
	println("hello world!", now)
}
