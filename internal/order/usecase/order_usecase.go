package usecase

import (
	"context"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/arslanmaratbekov/ap2-assignment2/internal/order/domain"
	"github.com/arslanmaratbekov/ap2-assignment2/internal/order/repository"
	"github.com/arslanmaratbekov/ap2-assignment2/internal/order/stream"
	"github.com/arslanmaratbekov/ap2-assignment2/internal/shared/paymentclient"
	paymentv1 "github.com/arslanmaratbekov/ap2-assignment2/pkg/gen/payment/v1"
)

type OrderUseCase struct {
	repo          repository.Repository
	paymentClient PaymentClient
	notifier      *stream.Notifier
}

type PaymentClient interface {
	ProcessPayment(ctx context.Context, input paymentclient.ProcessPaymentInput) (*paymentv1.PaymentResponse, error)
}

func NewOrderUseCase(
	repo repository.Repository,
	paymentClient PaymentClient,
	notifier *stream.Notifier,
) *OrderUseCase {
	return &OrderUseCase{
		repo:          repo,
		paymentClient: paymentClient,
		notifier:      notifier,
	}
}

func (u *OrderUseCase) CreateOrder(ctx context.Context, input domain.CreateOrderInput) (domain.Order, error) {
	now := time.Now().UTC()
	order := domain.Order{
		ID:        uuid.NewString(),
		UserID:    input.UserID,
		Amount:    input.Amount,
		Currency:  strings.ToUpper(input.Currency),
		Status:    domain.StatusPending,
		CreatedAt: now,
		UpdatedAt: now,
	}

	if err := u.repo.Create(ctx, order); err != nil {
		return domain.Order{}, fmt.Errorf("create order: %w", err)
	}

	paymentResponse, err := u.paymentClient.ProcessPayment(ctx, paymentclient.ProcessPaymentInput{
		OrderID:   order.ID,
		UserID:    order.UserID,
		Amount:    order.Amount,
		Currency:  order.Currency,
		CreatedAt: order.CreatedAt,
	})
	if err != nil {
		return domain.Order{}, fmt.Errorf("process payment over grpc: %w", err)
	}

	nextStatus := domain.StatusFailed
	if paymentResponse.GetStatus() == "APPROVED" || paymentResponse.GetStatus() == "REVIEW" {
		nextStatus = domain.StatusPaid
	}

	updatedOrder, err := u.UpdateStatus(ctx, order.ID, nextStatus)
	if err != nil {
		return domain.Order{}, err
	}

	return updatedOrder, nil
}

func (u *OrderUseCase) GetOrder(ctx context.Context, id string) (domain.Order, error) {
	return u.repo.GetByID(ctx, id)
}

func (u *OrderUseCase) UpdateStatus(ctx context.Context, orderID, status string) (domain.Order, error) {
	order, err := u.repo.UpdateStatus(ctx, orderID, strings.ToUpper(status))
	if err != nil {
		return domain.Order{}, fmt.Errorf("update order status: %w", err)
	}

	u.notifier.Notify(stream.Update{
		OrderID:   order.ID,
		Status:    order.Status,
		UpdatedAt: order.UpdatedAt,
	})

	return order, nil
}

func (u *OrderUseCase) Subscribe(orderID string) (<-chan stream.Update, func()) {
	return u.notifier.Subscribe(orderID)
}
