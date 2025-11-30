package main

import (
	"database/sql"
	"fmt"
	"log"
	"net/http"

	_ "github.com/lib/pq"
	"github.com/zack-canned/marvin-backend/services/user-tenant/internal/api"
	"github.com/zack-canned/marvin-backend/services/user-tenant/internal/auth"
	"github.com/zack-canned/marvin-backend/services/user-tenant/internal/config"
	"github.com/zack-canned/marvin-backend/services/user-tenant/internal/storage/postgres"
)

func main() {
	serverConfig, err := config.LoadServerConfig()
	if err != nil {
		log.Fatalf("Failed to load server configuration: %v", err)
	}

	dbConfig, err := config.LoadDBConfig()
	if err != nil {
		log.Fatalf("Failed to load database configuration: %v", err)
	}

	db, err := sql.Open("postgres", dbConfig.ConnString())
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}
	defer db.Close()

	if err := db.Ping(); err != nil {
		log.Fatalf("Failed to ping database: %v", err)
	}

	fmt.Println("Successfully connected to the database")

	userRepo := postgres.NewPostgresUserRepository(db)
	authService := auth.NewAuthService(userRepo)
	authHandler := auth.NewAuthHandler(authService)
	router := api.NewRouter(authHandler)

	addr := fmt.Sprintf("%s:%s", serverConfig.Host, serverConfig.Port)
	fmt.Printf("Server starting on %s...\n", addr)
	if err := http.ListenAndServe(addr, router); err != nil {
		log.Fatalf("Error starting server: %s\n", err)
	}
}