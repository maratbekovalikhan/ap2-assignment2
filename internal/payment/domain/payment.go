package domain

import "time"

type Payment struct {
	ID          string
	OrderID     string
	UserID      string
	Amount      float64
	Currency    string
	Status      string
	Message     string
	ProcessedAt time.Time
}
