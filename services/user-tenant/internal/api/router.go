package api

import (
	"net/http"

	"github.com/zack-canned/marvin-backend/services/user-tenant/internal/auth"
)

// NewRouter creates a new HTTP router.
func NewRouter(authHandler *auth.AuthHandler) *http.ServeMux {
	mux := http.NewServeMux()

	mux.HandleFunc("/register", authHandler.HandleRegister)
	mux.HandleFunc("/login", authHandler.HandleLogin)

	return mux
}
