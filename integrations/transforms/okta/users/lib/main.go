package main

import (
	"context"
	"encoding/json"
	"log"
	"os"
	"path/filepath"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/s3/manager"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-secretsmanager-caching-go/secretcache"
)

var s3Client *s3.Client

func ConfigS3() {
	region := os.Getenv("AWS_REGION")
	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(region))
	if err != nil {
		log.Fatal(err)
	}

	s3Client = s3.NewFromConfig(cfg)
}

type Secret struct {
	Username string `json:"username"`
	Password string `json:"password"`
	Engine   string `json:"engine"`
	Host     string `json:"host"`
}

type Response struct {
	KeyList []string
}

var (
	secretCache, _ = secretcache.New()
)

var (
	AWS_S3_REGION         = os.Getenv("AWS_S3_REGION")
	AWS_S3_SFN_TMP_BUCKET = os.Getenv("AWS_S3_SFN_TMP_BUCKET")
	SERVICE               = os.Getenv("CIRCULATE_SERVICE")
	ENDPOINT              = os.Getenv("CIRCULATE_ENDPOINT")
)

func GetSecret() (secret Secret) {
	database_secret_string := os.Getenv("DATABASE_SECRET")
	database_secret, _ := secretCache.GetSecretString(database_secret_string)

	var secret_result Secret
	json.Unmarshal([]byte(database_secret), &secret_result)

	return secret_result
}

// Download files from S3
// Add these downloaded files to EFS
// Use the secret from the Database Secrets Manager
// Generate a yml file for dbt/profiles.yml, then save that to EFS
// Profit???

func HandleRequest(lambdaCtx context.Context) {
	ConfigS3()

	dbtFilesBucketName := os.Getenv("AWS_S3_DATA_LAKE_IAC_BUCKET")
	dbtFilesBucketKey := os.Getenv("AWS_S3_DATA_LAKE_IAC_KEY")

	folder := "/tmp"
	filepath := filepath.Join(folder, filename)

	file, err := os.Create(filepath)
	if err != nil {
		log.Fatalf("Could not create file: %v", err)
	}
	defer file.Close()

	downloader := manager.NewDownloader(s3Client)
	numBytes, err := downloader.Download(context.TODO(), file, &s3.GetObjectInput{
		Bucket: aws.String(dbtFilesBucketName),
		Key:    aws.String(dbtFilesBucketKey),
	})
	if err != nil {
		log.Fatalf("Failed to download S3 file: %v", err)
	}

	keyList := []string{}

	session, err := session.NewSession(&aws.Config{Region: aws.String(AWS_S3_REGION)})
	if err != nil {
		log.Fatal(err)
	}

	secret := GetSecret()

}

func main() {
	lambda.Start(HandleRequest)
}
