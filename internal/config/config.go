package config

import (
	"fmt"
	"os"
	"strconv"

	"github.com/joho/godotenv"
)

type Config struct {
	OrderHTTPPort     string
	OrderGRPCHost     string
	OrderGRPCPort     string
	PaymentGRPCHost   string
	PaymentGRPCPort   string
	OrderDatabasePath string
	PaymentDefaultMsg string
}

func Load() (Config, error) {
	_ = godotenv.Load()

	cfg := Config{
		OrderHTTPPort:     getEnv("ORDER_HTTP_PORT", "8080"),
		OrderGRPCHost:     getEnv("ORDER_GRPC_HOST", "localhost"),
		OrderGRPCPort:     getEnv("ORDER_GRPC_PORT", "50052"),
		PaymentGRPCHost:   getEnv("PAYMENT_GRPC_HOST", "localhost"),
		PaymentGRPCPort:   getEnv("PAYMENT_GRPC_PORT", "50051"),
		OrderDatabasePath: getEnv("ORDER_DATABASE_PATH", "data/orders.db"),
		PaymentDefaultMsg: getEnv("PAYMENT_DEFAULT_MESSAGE", "payment processed successfully"),
	}

	if _, err := strconv.Atoi(cfg.OrderHTTPPort); err != nil {
		return Config{}, fmt.Errorf("invalid ORDER_HTTP_PORT: %w", err)
	}

	return cfg, nil
}

func (c Config) PaymentGRPCAddress() string {
	return fmt.Sprintf("%s:%s", c.PaymentGRPCHost, c.PaymentGRPCPort)
}

func (c Config) OrderGRPCAddress() string {
	return fmt.Sprintf("%s:%s", c.OrderGRPCHost, c.OrderGRPCPort)
}

func getEnv(key, fallback string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return fallback
}
