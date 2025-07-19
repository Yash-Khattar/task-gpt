package config

import (
	"context"
	"log"
	"os"
	"time"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type Config struct {
	MongoURI      string
	MongoDBName   string
	OpenAIKey     string
	CloudName     string
	CloudAPIKey   string
	CloudAPISecret string
	GeminiAPIKey  string
}

func Load() *Config {
	return &Config{
		MongoURI:      os.Getenv("MONGO_URI"),
		MongoDBName:   os.Getenv("MONGO_DBNAME"),
		OpenAIKey:     os.Getenv("OPENAI_API_KEY"),
		CloudName:     os.Getenv("CLOUDINARY_CLOUD_NAME"),
		CloudAPIKey:   os.Getenv("CLOUDINARY_API_KEY"),
		CloudAPISecret: os.Getenv("CLOUDINARY_API_SECRET"),
		GeminiAPIKey:  os.Getenv("GEMINI_API_KEY"),
	}
}

func InitMongo(cfg *Config) (*mongo.Client, *mongo.Database) {
	client, err := mongo.NewClient(options.Client().ApplyURI(cfg.MongoURI))
	if err != nil {
		log.Fatalf("Mongo client error: %v", err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := client.Connect(ctx); err != nil {
		log.Fatalf("Mongo connect error: %v", err)
	}
	return client, client.Database(cfg.MongoDBName)
} 