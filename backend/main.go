package main

import (
	"chatgpt_clone_backend/config"
	"chatgpt_clone_backend/handlers"
	"context"
	"log"
	"net/http"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	_ = godotenv.Load() // Loads .env file into environment variables
	cfg := config.Load()
	client, db := config.InitMongo(cfg)
	defer client.Disconnect(context.Background())

	r := gin.Default()

	r.POST("/chat", handlers.ChatHandler(cfg, db))
	r.GET("/history", handlers.HistoryHandler(db))
	r.GET("/history/:conversation_id", handlers.HistoryHandler(db))
	r.POST("/upload", handlers.UploadHandler(cfg, db))

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080" 
	}
	log.Printf("Listening on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
