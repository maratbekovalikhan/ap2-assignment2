package usecase

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"

	"github.com/arslanmaratbekov/ap2-assignment2/internal/payment/domain"
)

type ProcessPaymentInput struct {
	OrderID   string
	UserID    string
	Amount    float64
	Currency  string
	CreatedAt time.Time
}

type PaymentUseCase struct {
	defaultMessage string
}

func NewPaymentUseCase(defaultMessage string) *PaymentUseCase {
	return &PaymentUseCase{defaultMessage: defaultMessage}
}

func (u *PaymentUseCase) ProcessPayment(_ context.Context, input ProcessPaymentInput) (domain.Payment, error) {
	if input.OrderID == "" || input.UserID == "" {
		return domain.Payment{}, fmt.Errorf("order_id and user_id are required")
	}
	if input.Amount <= 0 {
		return domain.Payment{}, fmt.Errorf("amount must be positive")
	}

	status := "APPROVED"
	if input.Amount >= 10000 {
		status = "REVIEW"
	}

	return domain.Payment{
		ID:          uuid.NewString(),
		OrderID:     input.OrderID,
		UserID:      input.UserID,
		Amount:      input.Amount,
		Currency:    input.Currency,
		Status:      status,
		Message:     u.defaultMessage,
		ProcessedAt: time.Now().UTC(),
	}, nil
}
