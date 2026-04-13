package main

import (
	"log"
	"net"

	"google.golang.org/grpc"

	"github.com/arslanmaratbekov/ap2-assignment2/internal/config"
	paymentgrpc "github.com/arslanmaratbekov/ap2-assignment2/internal/payment/delivery/grpc"
	"github.com/arslanmaratbekov/ap2-assignment2/internal/payment/usecase"
	paymentv1 "github.com/arslanmaratbekov/ap2-assignment2/pkg/gen/payment/v1"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("load config: %v", err)
	}

	listener, err := net.Listen("tcp", cfg.PaymentGRPCAddress())
	if err != nil {
		log.Fatalf("listen payment grpc: %v", err)
	}

	server := grpc.NewServer(grpc.UnaryInterceptor(paymentgrpc.LoggingInterceptor()))
	paymentv1.RegisterPaymentServiceServer(
		server,
		paymentgrpc.NewServer(usecase.NewPaymentUseCase(cfg.PaymentDefaultMsg)),
	)

	log.Printf("payment service listening on %s", cfg.PaymentGRPCAddress())
	if err := server.Serve(listener); err != nil {
		log.Fatalf("serve payment grpc: %v", err)
	}
}
