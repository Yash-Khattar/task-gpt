# Go Backend for ChatGPT Clone

## Features
- OpenAI Chat Completion API integration
- MongoDB chat history (conversation ID, timestamp, messages, model, image URLs)
- File uploads to Cloudinary, metadata in MongoDB
- Model selection per request

## Setup

### 1. Environment Variables
Set these in your shell or a .env file:
```
MONGO_URI=your_mongodb_uri
MONGO_DBNAME=your_db_name
OPENAI_API_KEY=your_openai_key
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_cloudinary_api_key
CLOUDINARY_API_SECRET=your_cloudinary_api_secret
```

### 2. Install dependencies
```
cd backend
go mod tidy
```

### 3. Run the server
```
go run main.go
```

## API Endpoints

### POST /chat
Send a message and get an AI response. Saves to MongoDB.
```
{
  "conversation_id": "string",
  "message": "string",
  "model": "gpt-3.5-turbo",
  "image_url": "optional"
}
```
Response:
```
{
  "ai_response": "string"
}
```

### GET /history/:conversation_id
Get all messages and metadata for a conversation.

### POST /upload
Upload an image file (multipart/form-data, field: `file`).
Response:
```
{
  "url": "https://..."
}
``` 