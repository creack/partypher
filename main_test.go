package main

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/creack/partypher/api"
	"github.com/creack/partypher/db"
	"github.com/google/uuid"
	"github.com/jmoiron/sqlx"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func newTestController(t *testing.T) *controller {
	t.Helper()

	c, err := newController(context.Background())
	require.NoError(t, err, "Error creating new test controller.")
	return c
}

func deletePart(dbx *sqlx.DB, partName string) {
	_, _ = dbx.ExecContext(context.Background(), dbx.Rebind(`DELETE FROM parts WHERE part_name = ?`), partName) // Best effort.
}

func insertPart(t *testing.T, dbx *sqlx.DB) api.Part {
	p := db.Part{ID: uuid.New(), Name: "test_part_" + uuid.New().String()}
	require.NoError(t, db.InsertPart(context.Background(), dbx, p), "Error inserting test part in db.")
	return api.Part{ID: p.ID, Name: p.Name}
}

func TestCreatePartHandler(t *testing.T) {
	t.Parallel()
	c := newTestController(t)

	t.Run("happy_path", func(t *testing.T) {
		t.Parallel()
		partName := "testpart_" + uuid.New().String()
		defer deletePart(c.db, partName)

		w := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodPost, "/", strings.NewReader(`{"part_name":"`+partName+`"}`))

		c.createPartHandler(w, req)

		require.Equal(t, http.StatusCreated, w.Code, "Unexpected status code inserting a new part via handler.")

		var p api.Part
		require.NoError(t, json.Unmarshal(w.Body.Bytes(), &p), "Error parsing handler response for insert part.")

		assert.NotEqual(t, uuid.Nil, p.ID, "Part ID should not be nil.")
		assert.Equal(t, partName, p.Name, "Created part name didn't match the requested one.")

		// TODO: Test metadata.
	})

	t.Run("err_no_payload", func(t *testing.T) {
		t.Parallel()
		partName := "testpart_" + uuid.New().String()
		defer deletePart(c.db, partName)

		w := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodPost, "/", nil)

		c.createPartHandler(w, req)

		require.Equal(t, http.StatusBadRequest, w.Code, "Unexpected status code inserting a new part via handler.")
	})

	t.Run("err_empty_payload", func(t *testing.T) {
		t.Parallel()
		partName := "testpart_" + uuid.New().String()
		defer deletePart(c.db, partName)

		w := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodPost, "/", strings.NewReader(`{}`))

		c.createPartHandler(w, req)

		require.Equal(t, http.StatusBadRequest, w.Code, "Unexpected status code inserting a new part via handler.")
	})

	t.Run("err_bad_part_name", func(t *testing.T) {
		t.Parallel()
		partName := "testpart_" + uuid.New().String()
		defer deletePart(c.db, partName)

		w := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodPost, "/", strings.NewReader(`{"part_name":"`+strings.Repeat("hello", 1024)+`"}`))

		c.createPartHandler(w, req)

		require.Equal(t, http.StatusBadRequest, w.Code, "Unexpected status code inserting a new part via handler.")
	})

}

func TestGetPartHandler(t *testing.T) {
	t.Parallel()
	c := newTestController(t)

	t.Run("happy_path", func(t *testing.T) {
		t.Parallel()
		p := insertPart(t, c.db)
		defer deletePart(c.db, p.Name)

		w := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodGet, "/?part_id="+p.ID.String(), nil)

		c.getPartHandler(w, req)

		require.Equal(t, http.StatusOK, w.Code, "Unexpected status fetching part. (%s)", w.Body)

		got := map[string]interface{}{}
		require.NoError(t, json.Unmarshal(w.Body.Bytes(), &got), "Error parsing handler response for insert part.")

		assert.Equal(t, p.ID.String(), got["part_id"], "Unexpected value of fetched part_id.")
		assert.Equal(t, p.Name, got["part_name"], "Unexpected value of fetched part_namee.")

		// TODO: Handle time metadata.
	})

	t.Run("missing_part_id", func(t *testing.T) {
		t.Parallel()

		w := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodGet, "/", nil)

		c.getPartHandler(w, req)

		require.Equal(t, http.StatusBadRequest, w.Code, "Unexpected status fetching part with missing/empty part_id. (%s)", w.Body)
	})

	t.Run("invalid_part_id", func(t *testing.T) {
		t.Parallel()

		w := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodGet, "/?part_id=abcdef", nil)

		c.getPartHandler(w, req)

		require.Equal(t, http.StatusBadRequest, w.Code, "Unexpected status fetching part with invalid part_id. (%s)", w.Body)
	})

	t.Run("part_not_found", func(t *testing.T) {
		t.Parallel()
		p := insertPart(t, c.db)
		defer deletePart(c.db, p.Name)

		w := httptest.NewRecorder()
		req := httptest.NewRequest(http.MethodGet, "/?part_id="+uuid.New().String(), nil)

		c.getPartHandler(w, req)

		require.Equal(t, http.StatusNotFound, w.Code, "Unexpected status fetching unexisting part. (%s)", w.Body)
	})
}
