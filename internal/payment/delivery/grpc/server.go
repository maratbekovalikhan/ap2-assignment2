package grpc

import (
	"context"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/arslanmaratbekov/ap2-assignment2/internal/payment/usecase"
	paymentv1 "github.com/arslanmaratbekov/ap2-assignment2/pkg/gen/payment/v1"
)

type Server struct {
	paymentv1.UnimplementedPaymentServiceServer
	paymentUseCase *usecase.PaymentUseCase
}

func NewServer(paymentUseCase *usecase.PaymentUseCase) *Server {
	return &Server{paymentUseCase: paymentUseCase}
}

func (s *Server) ProcessPayment(ctx context.Context, req *paymentv1.PaymentRequest) (*paymentv1.PaymentResponse, error) {
	if req.GetOrderId() == "" || req.GetUserId() == "" {
		return nil, status.Error(codes.InvalidArgument, "order_id and user_id are required")
	}

	payment, err := s.paymentUseCase.ProcessPayment(ctx, usecase.ProcessPaymentInput{
		OrderID:   req.GetOrderId(),
		UserID:    req.GetUserId(),
		Amount:    req.GetAmount(),
		Currency:  req.GetCurrency(),
		CreatedAt: req.GetCreatedAt().AsTime(),
	})
	if err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}

	return &paymentv1.PaymentResponse{
		PaymentId:   payment.ID,
		OrderId:     payment.OrderID,
		Status:      payment.Status,
		Message:     payment.Message,
		ProcessedAt: timestamppb.New(payment.ProcessedAt),
	}, nil
}
