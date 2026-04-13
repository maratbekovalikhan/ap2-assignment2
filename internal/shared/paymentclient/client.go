package paymentclient

import (
	"context"
	"fmt"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/protobuf/types/known/timestamppb"

	paymentv1 "github.com/arslanmaratbekov/ap2-assignment2/pkg/gen/payment/v1"
)

type Client struct {
	conn   *grpc.ClientConn
	client paymentv1.PaymentServiceClient
}

type ProcessPaymentInput struct {
	OrderID   string
	UserID    string
	Amount    float64
	Currency  string
	CreatedAt time.Time
}

func New(address string) (*Client, error) {
	conn, err := grpc.Dial(address, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return nil, fmt.Errorf("create grpc client: %w", err)
	}

	return &Client{
		conn:   conn,
		client: paymentv1.NewPaymentServiceClient(conn),
	}, nil
}

func (c *Client) Close() error {
	return c.conn.Close()
}

func (c *Client) ProcessPayment(ctx context.Context, input ProcessPaymentInput) (*paymentv1.PaymentResponse, error) {
	return c.client.ProcessPayment(ctx, &paymentv1.PaymentRequest{
		OrderId:   input.OrderID,
		UserId:    input.UserID,
		Amount:    input.Amount,
		Currency:  input.Currency,
		CreatedAt: timestamppb.New(input.CreatedAt),
	})
}
