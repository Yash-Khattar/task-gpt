package handlers

import (
	"chatgpt_clone_backend/config"
	"chatgpt_clone_backend/models"
	"chatgpt_clone_backend/utils"
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

type ChatRequest struct {
	ConversationID string                   `json:"conversation_id"`
	Message        string                   `json:"message"`
	Model          string                   `json:"model"`
	ImageURL       string                   `json:"image_url,omitempty"`
	Context        []map[string]interface{} `json:"context,omitempty"`
}

type ChatResponse struct {
	AIResponse string `json:"ai_response"`
}

func ChatHandler(cfg *config.Config, db *mongo.Database) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req ChatRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request"})
			return
		}
		model := req.Model
		fmt.Print(model)
		if model == "" {
			model = "gemini-pro"
		}
		var contextMsgs []utils.GeminiMessage
		if len(req.Context) > 0 {
			for _, m := range req.Context {
				role := "user"
				if isUser, ok := m["is_user"].(bool); ok && !isUser {
					role = "model"
				}
				if text, ok := m["text"].(string); ok && text != "" {
					contextMsgs = append(contextMsgs, utils.GeminiMessage{
						Role:  role,
						Parts: []utils.GeminiPart{{Text: text}},
					})
				}
			}
		}
		userMsg := utils.GeminiMessage{
			Role:  "user",
			Parts: []utils.GeminiPart{{Text: req.Message}},
		}
		allMsgs := append(contextMsgs, userMsg)
		aiResp, err := utils.GetGeminiCompletion(cfg, allMsgs, model)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}
		msgList := []models.ChatMessage{
			{Text: req.Message, IsUser: true, ImageURL: req.ImageURL, Timestamp: time.Now()},
			{Text: aiResp, IsUser: false, Timestamp: time.Now()},
		}
		filter := bson.M{"conversation_id": req.ConversationID}
		update := bson.M{
			"$push":        bson.M{"messages": bson.M{"$each": msgList}},
			"$setOnInsert": bson.M{"created_at": time.Now(), "model": model, "conversation_id": req.ConversationID},
		}
		upsert := true
		_, err = db.Collection("conversations").UpdateOne(context.Background(), filter, update, &options.UpdateOptions{Upsert: &upsert})
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "DB error"})
			return
		}
		c.JSON(http.StatusOK, ChatResponse{AIResponse: aiResp})
	}
}
