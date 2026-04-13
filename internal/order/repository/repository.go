package repository

import (
	"context"

	"github.com/arslanmaratbekov/ap2-assignment2/internal/order/domain"
)

type Repository interface {
	Create(ctx context.Context, order domain.Order) error
	GetByID(ctx context.Context, id string) (domain.Order, error)
	UpdateStatus(ctx context.Context, id, status string) (domain.Order, error)
}
