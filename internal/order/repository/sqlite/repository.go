package sqlite

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"time"

	_ "modernc.org/sqlite"

	"github.com/arslanmaratbekov/ap2-assignment2/internal/order/domain"
)

type Repository struct {
	db *sql.DB
}

func New(path string) (*Repository, error) {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return nil, fmt.Errorf("create db directory: %w", err)
	}

	db, err := sql.Open("sqlite", path)
	if err != nil {
		return nil, fmt.Errorf("open sqlite db: %w", err)
	}

	repo := &Repository{db: db}
	if err := repo.migrate(); err != nil {
		return nil, err
	}

	return repo, nil
}

func (r *Repository) Close() error {
	return r.db.Close()
}

func (r *Repository) Create(ctx context.Context, order domain.Order) error {
	_, err := r.db.ExecContext(
		ctx,
		`INSERT INTO orders (id, user_id, amount, currency, status, created_at, updated_at)
		 VALUES (?, ?, ?, ?, ?, ?, ?)`,
		order.ID,
		order.UserID,
		order.Amount,
		order.Currency,
		order.Status,
		order.CreatedAt.UTC(),
		order.UpdatedAt.UTC(),
	)
	return err
}

func (r *Repository) GetByID(ctx context.Context, id string) (domain.Order, error) {
	var order domain.Order

	err := r.db.QueryRowContext(
		ctx,
		`SELECT id, user_id, amount, currency, status, created_at, updated_at
		 FROM orders WHERE id = ?`,
		id,
	).Scan(
		&order.ID,
		&order.UserID,
		&order.Amount,
		&order.Currency,
		&order.Status,
		&order.CreatedAt,
		&order.UpdatedAt,
	)
	if errors.Is(err, sql.ErrNoRows) {
		return domain.Order{}, fmt.Errorf("order not found")
	}
	return order, err
}

func (r *Repository) UpdateStatus(ctx context.Context, id, status string) (domain.Order, error) {
	now := time.Now().UTC()

	result, err := r.db.ExecContext(
		ctx,
		`UPDATE orders SET status = ?, updated_at = ? WHERE id = ?`,
		status,
		now,
		id,
	)
	if err != nil {
		return domain.Order{}, err
	}

	affected, err := result.RowsAffected()
	if err != nil {
		return domain.Order{}, err
	}
	if affected == 0 {
		return domain.Order{}, fmt.Errorf("order not found")
	}

	return r.GetByID(ctx, id)
}

func (r *Repository) migrate() error {
	_, err := r.db.Exec(`
		CREATE TABLE IF NOT EXISTS orders (
			id TEXT PRIMARY KEY,
			user_id TEXT NOT NULL,
			amount REAL NOT NULL,
			currency TEXT NOT NULL,
			status TEXT NOT NULL,
			created_at TIMESTAMP NOT NULL,
			updated_at TIMESTAMP NOT NULL
		);
	`)
	if err != nil {
		return fmt.Errorf("migrate orders table: %w", err)
	}
	return nil
}
