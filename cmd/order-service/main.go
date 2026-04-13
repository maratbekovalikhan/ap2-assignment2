package main

import (
	"log"
	"net"

	"github.com/gin-gonic/gin"
	"google.golang.org/grpc"

	"github.com/arslanmaratbekov/ap2-assignment2/internal/config"
	ordergrpc "github.com/arslanmaratbekov/ap2-assignment2/internal/order/delivery/grpc"
	orderhttp "github.com/arslanmaratbekov/ap2-assignment2/internal/order/delivery/http"
	ordersqlite "github.com/arslanmaratbekov/ap2-assignment2/internal/order/repository/sqlite"
	"github.com/arslanmaratbekov/ap2-assignment2/internal/order/stream"
	"github.com/arslanmaratbekov/ap2-assignment2/internal/order/usecase"
	"github.com/arslanmaratbekov/ap2-assignment2/internal/shared/paymentclient"
	orderv1 "github.com/arslanmaratbekov/ap2-assignment2/pkg/gen/order/v1"
)

func main() {
	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("load config: %v", err)
	}

	repo, err := ordersqlite.New(cfg.OrderDatabasePath)
	if err != nil {
		log.Fatalf("init order repository: %v", err)
	}
	defer repo.Close()

	paymentClient, err := paymentclient.New(cfg.PaymentGRPCAddress())
	if err != nil {
		log.Fatalf("init payment grpc client: %v", err)
	}
	defer paymentClient.Close()

	notifier := stream.NewNotifier()
	orderUseCase := usecase.NewOrderUseCase(repo, paymentClient, notifier)

	go runHTTP(cfg.OrderHTTPPort, orderUseCase)
	runGRPC(cfg.OrderGRPCAddress(), orderUseCase)
}

func runHTTP(port string, orderUseCase *usecase.OrderUseCase) {
	router := gin.Default()
	orderhttp.NewHandler(orderUseCase).RegisterRoutes(router)

	log.Printf("order http service listening on :%s", port)
	if err := router.Run(":" + port); err != nil {
		log.Fatalf("serve order http: %v", err)
	}
}

func runGRPC(address string, orderUseCase *usecase.OrderUseCase) {
	listener, err := net.Listen("tcp", address)
	if err != nil {
		log.Fatalf("listen order grpc: %v", err)
	}

	server := grpc.NewServer()
	orderv1.RegisterOrderServiceServer(server, ordergrpc.NewServer(orderUseCase))

	log.Printf("order grpc service listening on %s", address)
	if err := server.Serve(listener); err != nil {
		log.Fatalf("serve order grpc: %v", err)
	}
}
