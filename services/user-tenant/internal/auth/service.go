package auth

import (
	"context"

	"github.com/zack-canned/marvin-backend/services/user-tenant/internal/user"
	"golang.org/x/crypto/bcrypt"
)

// AuthService provides authentication-related business logic.
type AuthService interface {
	Register(ctx context.Context, email, password string) (*user.User, error)
	Login(ctx context.Context, email, password string) (*user.User, error) // In a real app, this would return a token
}

type authService struct {
	userRepo user.Repository
}

// NewAuthService creates a new AuthService.
func NewAuthService(userRepo user.Repository) AuthService {
	return &authService{userRepo: userRepo}
}

// Register creates a new user.
func (s *authService) Register(ctx context.Context, email, password string) (*user.User, error) {
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	u := user.User{
		Email:    email,
		Password: string(hashedPassword),
	}

	err = s.userRepo.CreateUser(ctx, u)
	if err != nil {
		return nil, err
	}

	// Clear password before returning user
	u.Password = ""
	return &u, nil
}

// Login authenticates a user.
func (s *authService) Login(ctx context.Context, email, password string) (*user.User, error) {
	u, err := s.userRepo.GetUserByEmail(ctx, email)
	if err != nil {
		return nil, err
	}

	err = bcrypt.CompareHashAndPassword([]byte(u.Password), []byte(password))
	if err != nil {
		return nil, err // Invalid password
	}

	// Clear password before returning user
	u.Password = ""
	return u, nil
}
