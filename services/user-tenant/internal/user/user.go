package user

import "context"

// User represents a user in the system.
type User struct {
	ID       string `json:"id"`
	Email    string `json:"email"`
	Password string `json:"-"` // Store password hashes, not plaintext
}

// Repository defines the interface for user data storage.
type Repository interface {
	CreateUser(ctx context.Context, user User) error
	GetUserByEmail(ctx context.Context, email string) (*User, error)
}
