package postgres

import (
	"context"
	"database/sql"

	"github.com/google/uuid"
	"github.com/zack-canned/marvin-backend/services/user-tenant/internal/user"
)

// PostgresUserRepository is a PostgreSQL implementation of the user.Repository.
type PostgresUserRepository struct {
	db *sql.DB
}

// NewPostgresUserRepository creates a new PostgresUserRepository.
func NewPostgresUserRepository(db *sql.DB) *PostgresUserRepository {
	return &PostgresUserRepository{db: db}
}

// CreateUser creates a new user in the database.
func (r *PostgresUserRepository) CreateUser(ctx context.Context, u user.User) error {
	u.ID = uuid.New().String()
	query := "INSERT INTO users (id, email, password) VALUES ($1, $2, $3)"
	_, err := r.db.ExecContext(ctx, query, u.ID, u.Email, u.Password)
	return err
}

// GetUserByEmail retrieves a user by their email address.
func (r *PostgresUserRepository) GetUserByEmail(ctx context.Context, email string) (*user.User, error) {
	u := &user.User{}
	query := "SELECT id, email, password FROM users WHERE email = $1"
	err := r.db.QueryRowContext(ctx, query, email).Scan(&u.ID, &u.Email, &u.Password)
	if err != nil {
		return nil, err
	}
	return u, nil
}
