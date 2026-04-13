package grpc

import (
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/arslanmaratbekov/ap2-assignment2/internal/order/usecase"
	orderv1 "github.com/arslanmaratbekov/ap2-assignment2/pkg/gen/order/v1"
)

type Server struct {
	orderv1.UnimplementedOrderServiceServer
	orderUseCase *usecase.OrderUseCase
}

func NewServer(orderUseCase *usecase.OrderUseCase) *Server {
	return &Server{orderUseCase: orderUseCase}
}

func (s *Server) SubscribeToOrderUpdates(req *orderv1.OrderRequest, stream orderv1.OrderService_SubscribeToOrderUpdatesServer) error {
	updates, cancel := s.orderUseCase.Subscribe(req.GetOrderId())
	defer cancel()

	order, err := s.orderUseCase.GetOrder(stream.Context(), req.GetOrderId())
	if err == nil {
		if err := stream.Send(&orderv1.OrderStatusUpdate{
			OrderId:   order.ID,
			Status:    order.Status,
			UpdatedAt: timestamppb.New(order.UpdatedAt),
		}); err != nil {
			return err
		}
	}

	for {
		select {
		case <-stream.Context().Done():
			return nil
		case update, ok := <-updates:
			if !ok {
				return nil
			}
			if err := stream.Send(&orderv1.OrderStatusUpdate{
				OrderId:   update.OrderID,
				Status:    update.Status,
				UpdatedAt: timestamppb.New(update.UpdatedAt),
			}); err != nil {
				return err
			}
		}
	}
}
