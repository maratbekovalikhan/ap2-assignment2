package domain

import "time"

type Order struct {
	ID        string
	UserID    string
	Amount    float64
	Currency  string
	Status    string
	CreatedAt time.Time
	UpdatedAt time.Time
}

type CreateOrderInput struct {
	UserID   string  `json:"user_id" binding:"required"`
	Amount   float64 `json:"amount" binding:"required,gt=0"`
	Currency string  `json:"currency" binding:"required"`
}

type UpdateStatusInput struct {
	Status string `json:"status" binding:"required"`
}

const (
	StatusPending   = "PENDING"
	StatusPaid      = "PAID"
	StatusFailed    = "FAILED"
	StatusCancelled = "CANCELLED"
)
