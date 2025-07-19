package utils

import (
	"context"
	"chatgpt_clone_backend/config"

	"github.com/cloudinary/cloudinary-go/v2"
	"github.com/cloudinary/cloudinary-go/v2/api/uploader"
)

func UploadToCloudinary(cfg *config.Config, filePath string) (string, error) {
	cld, err := cloudinary.NewFromParams(cfg.CloudName, cfg.CloudAPIKey, cfg.CloudAPISecret)
	if err != nil {
		return "", err
	}
	resp, err := cld.Upload.Upload(context.Background(), filePath, uploader.UploadParams{})
	if err != nil {
		return "", err
	}
	return resp.SecureURL, nil
} 