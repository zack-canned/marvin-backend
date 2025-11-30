package auth

import (
	"context"
	"encoding/json"
	"net/http"
)

// AuthHandler handles HTTP requests for authentication.
type AuthHandler struct {
	service AuthService
}

// NewAuthHandler creates a new AuthHandler.
func NewAuthHandler(service AuthService) *AuthHandler {
	return &AuthHandler{service: service}
}

// RegisterRequest defines the request payload for registration.
type RegisterRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

// LoginRequest defines the request payload for login.
type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

// UserResponse defines the response payload for a user.
type UserResponse struct {
	ID    string `json:"id"`
	Email string `json:"email"`
}

// HandleRegister handles the registration of a new user.
func (h *AuthHandler) HandleRegister(w http.ResponseWriter, r *http.Request) {
	var req RegisterRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	u, err := h.service.Register(context.Background(), req.Email, req.Password)
	if err != nil {
		http.Error(w, "Failed to register user", http.StatusInternalServerError)
		return
	}

	res := UserResponse{
		ID:    u.ID,
		Email: u.Email,
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(res)
}

// HandleLogin handles user login.
func (h *AuthHandler) HandleLogin(w http.ResponseWriter, r *http.Request) {
	var req LoginRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}

	u, err := h.service.Login(context.Background(), req.Email, req.Password)
	if err != nil {
		// In a real app, you'd distinguish between "not found" and "invalid password"
		// but for simplicity, we'll return a generic error.
		http.Error(w, "Invalid credentials", http.StatusUnauthorized)
		return
	}

	res := UserResponse{
		ID:    u.ID,
		Email: u.Email,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(res)
}
