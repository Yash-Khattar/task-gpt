package models

import (
	"go.mongodb.org/mongo-driver/bson/primitive"
	"time"
)

type ChatMessage struct {
	Text      string    `bson:"text,omitempty" json:"text,omitempty"`
	IsUser    bool      `bson:"is_user" json:"is_user"`
	ImageURL  string    `bson:"image_url,omitempty" json:"image_url,omitempty"`
	Timestamp time.Time `bson:"timestamp" json:"timestamp"`
}

type Conversation struct {
	ID            primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	ConversationID string            `bson:"conversation_id" json:"conversation_id"`
	Messages      []ChatMessage      `bson:"messages" json:"messages"`
	Model         string             `bson:"model" json:"model"`
	CreatedAt     time.Time          `bson:"created_at" json:"created_at"`
} 