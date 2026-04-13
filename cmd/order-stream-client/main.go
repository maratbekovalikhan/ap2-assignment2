package main

import (
	"context"
	"flag"
	"fmt"
	"log"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	"github.com/arslanmaratbekov/ap2-assignment2/internal/config"
	orderv1 "github.com/arslanmaratbekov/ap2-assignment2/pkg/gen/order/v1"
)

func main() {
	orderID := flag.String("order-id", "", "order id to subscribe to")
	flag.Parse()

	if *orderID == "" {
		log.Fatal("order-id is required")
	}

	cfg, err := config.Load()
	if err != nil {
		log.Fatalf("load config: %v", err)
	}

	conn, err := grpc.Dial(cfg.OrderGRPCAddress(), grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		log.Fatalf("create order grpc client: %v", err)
	}
	defer conn.Close()

	client := orderv1.NewOrderServiceClient(conn)
	stream, err := client.SubscribeToOrderUpdates(context.Background(), &orderv1.OrderRequest{
		OrderId: *orderID,
	})
	if err != nil {
		log.Fatalf("subscribe to order updates: %v", err)
	}

	log.Printf("subscribed to order %s", *orderID)
	for {
		update, err := stream.Recv()
		if err != nil {
			log.Fatalf("receive order update: %v", err)
		}
		fmt.Printf("order=%s status=%s updated_at=%s\n", update.GetOrderId(), update.GetStatus(), update.GetUpdatedAt().AsTime())
	}
}
