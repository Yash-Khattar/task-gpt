package handlers

import (
	"chatgpt_clone_backend/config"
	"chatgpt_clone_backend/utils"
	"context"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
)

type UploadResponse struct {
	URL string `json:"url"`
}

func UploadHandler(cfg *config.Config, db *mongo.Database) gin.HandlerFunc {
	return func(c *gin.Context) {
		file, err := c.FormFile("file")
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "No file uploaded"})
			return
		}
		localPath := "/tmp/" + file.Filename
		if err := c.SaveUploadedFile(file, localPath); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save file"})
			return
		}
		url, err := utils.UploadToCloudinary(cfg, localPath)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Cloudinary upload failed"})
			return
		}
		meta := bson.M{"url": url, "filename": file.Filename, "uploaded_at": time.Now()}
		_, _ = db.Collection("uploads").InsertOne(context.Background(), meta)
		c.JSON(http.StatusOK, UploadResponse{URL: url})
	}
} 