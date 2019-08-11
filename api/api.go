package api

import (
	"time"

	"github.com/google/uuid"
)

// TimeMetadata is the common time metadata fields for all components.
type TimeMetadata struct {
	CreatedAt time.Time  `json:"created_at"`
	UpdatedAt time.Time  `json:"updated_at"`
	DeletedAt *time.Time `json:"deleted_at,omitempty"`
}

// Part .
type Part struct {
	ID   uuid.UUID `json:"part_id"`
	Name string    `json:"part_name"`

	TimeMetadata
}

// CreatePartRequest is the expected payload to create a new part.
type CreatePartRequest struct {
	Name string `json:"part_name"`
}
