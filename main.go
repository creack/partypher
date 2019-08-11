package main

import (
	"context"
	"encoding/json"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/creack/partypher/api"
	"github.com/creack/partypher/db"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	_ "github.com/lib/pq" // Load the postgres driver.
	"github.com/pkg/errors"
)

type controller struct {
	db *sqlx.DB
}

func newController(ctx context.Context) (*controller, error) {
	db, err := sqlx.ConnectContext(ctx, "postgres", os.Getenv("PG_DSN"))
	if err != nil {
		return nil, errors.Wrap(err, "sqlx.Connect")
	}
	return &controller{db: db}, nil
}

func (c *controller) createPartHandler(w http.ResponseWriter, req *http.Request) {
	ctx := req.Context()

	buf, err := ioutil.ReadAll(req.Body)
	if err != nil {
		log.Printf("Error consuming body: %s.\n", err)
		return
	}
	_ = req.Body.Close() // Best effort.

	var reqPart api.CreatePartRequest
	if err := json.Unmarshal(buf, &reqPart); err != nil {
		http.Error(w, errors.Wrap(err, "unmarshal body").Error(), http.StatusBadRequest)
		log.Printf("Error parsing body: %s.\n", err)
		return
	}

	now := time.Now()
	dbPart := db.Part{
		ID:   uuid.New(),
		Name: reqPart.Name,
		TimeMetadata: db.TimeMetadata{
			CreatedAt: now,
			UpdatedAt: now,
		},
	}

	if err := db.InsertPart(ctx, c.db, dbPart); err != nil {
		log.Printf("Error inserting part in db: %s.\n", err)
		http.Error(w, "Internal error.", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)

	apiPart := api.Part{
		ID:   dbPart.ID,
		Name: dbPart.Name,
		TimeMetadata: api.TimeMetadata{
			CreatedAt: dbPart.CreatedAt,
			UpdatedAt: dbPart.UpdatedAt,
		},
	}

	enc := json.NewEncoder(w)
	enc.SetIndent("", "  ")

	if err := enc.Encode(apiPart); err != nil {
		log.Printf("Error encoding/sending the api part to the client: %s.\n", err)
		return
	}
}

func (c *controller) getPartHandler(w http.ResponseWriter, req *http.Request) {
	if err := req.ParseForm(); err != nil {
		http.Error(w, errors.Wrap(err, "parseForm").Error(), http.StatusBadRequest)
		return
	}

	partID, err := uuid.Parse(req.Form.Get("part_id"))
	if err != nil {
		http.Error(w, errors.Wrap(err, "parse partID").Error(), http.StatusBadRequest)
		return
	}

	ctx := req.Context()

	dbPart, err := db.GetPart(ctx, c.db, partID)
	if err != nil {
		log.Printf("Error getting part in db: %s.\n", err)
		http.Error(w, "Internal error.", http.StatusInternalServerError)
		return
	}

	apiPart := api.Part{
		ID:   dbPart.ID,
		Name: dbPart.Name,
		TimeMetadata: api.TimeMetadata{
			CreatedAt: dbPart.CreatedAt,
			UpdatedAt: dbPart.UpdatedAt,
		},
	}
	if !dbPart.DeletedAt.IsZero() {
		apiPart.TimeMetadata.DeletedAt = &dbPart.DeletedAt
	}

	enc := json.NewEncoder(w)
	enc.SetIndent("", "  ")

	if err := enc.Encode(apiPart); err != nil {
		log.Printf("Error encoding/sending the api part to the client: %s.\n", err)
		return
	}
}

func main() {
	ctx := context.Background()

	c, err := newController(ctx)
	if err != nil {
		panic(errors.Wrap(err, "newController"))
	}

	http.HandleFunc("/post", c.createPartHandler)
	http.HandleFunc("/get", c.getPartHandler)
	println("ready!")
	if err := http.ListenAndServe(":8080", nil); err != nil {
		panic(err)
	}
}
