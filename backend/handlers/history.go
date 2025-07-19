package handlers

import (
	"chatgpt_clone_backend/models"
	"context"
	"net/http"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

func HistoryHandler(db *mongo.Database) gin.HandlerFunc {
	return func(c *gin.Context) {
		convID := c.Param("conversation_id")
		if convID == "" {
			// List all conversations
			cursor, err := db.Collection("conversations").Find(context.Background(), bson.M{})
			if err != nil {
				c.JSON(http.StatusInternalServerError, gin.H{"error": "DB error"})
				return
			}
			defer cursor.Close(context.Background())
			var results []bson.M
			for cursor.Next(context.Background()) {
				var conv bson.M
				if err := cursor.Decode(&conv); err == nil {
					results = append(results, bson.M{
						"conversation_id": conv["conversation_id"],
						"created_at": conv["created_at"],
						"title": conv["title"],
					})
				}
			}
			c.JSON(http.StatusOK, results)
			return
		}
		// Get a single conversation
		var conv models.Conversation
		err := db.Collection("conversations").FindOne(context.Background(), bson.M{"conversation_id": convID}).Decode(&conv)
		if err != nil {
			if err == mongo.ErrNoDocuments {
				c.JSON(http.StatusNotFound, gin.H{"error": "Conversation not found"})
				return
			}
			c.JSON(http.StatusInternalServerError, gin.H{"error": "DB error"})
			return
		}
		c.JSON(http.StatusOK, conv)
	}
} 