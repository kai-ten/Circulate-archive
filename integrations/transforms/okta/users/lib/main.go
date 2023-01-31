package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"strings"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/s3/manager"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-secretsmanager-caching-go/secretcache"
	"gopkg.in/yaml.v3"
)

var (
	EFS_MOUNT_PATH        = os.Getenv("EFS_MOUNT_PATH")
	AWS_S3_REGION         = os.Getenv("AWS_S3_REGION")
	AWS_S3_SFN_TMP_BUCKET = os.Getenv("AWS_S3_SFN_TMP_BUCKET")
	SERVICE               = os.Getenv("CIRCULATE_SERVICE")
	ENDPOINT              = os.Getenv("CIRCULATE_ENDPOINT")
	DATABASE_SECRET       = os.Getenv("DATABASE_SECRET")
)

var (
	secretCache, _ = secretcache.New()
)

type Config struct {
	Type     string `yaml:"type"`
	Host     string `yaml:"host"`
	User     string `yaml:"user"`
	Password string `yaml:"password"`
	Port     int    `yaml:"port"`
	Dbname   string `yaml:"dbname"`
	Schema   string `yaml:"schema"`
	Threads  int    `yaml:"threads"`
}

type Outputs struct {
	Config Config `yaml:"env"`
}

type Project struct {
	Target  string  `yaml:"target"`
	Outputs Outputs `yaml:"outputs"`
}

type Profile struct {
	Project Project `yaml:"circulate"`
}

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

func GetSecret() (secret Secret) {
	database_secret_string := os.Getenv("DATABASE_SECRET")
	database_secret, _ := secretCache.GetSecretString(database_secret_string)

	var secret_result Secret
	json.Unmarshal([]byte(database_secret), &secret_result)

	return secret_result
}

// Download files from S3, list all files in path, then use the path to create file in EFS mount
// Add these downloaded files to EFS
// Use the secret from the Database Secrets Manager
// Generate a yml file for dbt/profiles.yml, then save that to EFS
// Profit???

func StoreDbtObjects(ctx context.Context, dbtFilesBucketName string, dbtFilesBucketKey string) error {

	input := &s3.ListObjectsV2Input{
		Bucket: &dbtFilesBucketName,
		Prefix: &dbtFilesBucketKey,
	}

	o, err := s3Client.ListObjectsV2(context.Background(), input)
	if err != nil {
		log.Print("Error listing objects")
		return err
	}

	for _, o := range o.Contents {
		filepath := strings.ReplaceAll(*o.Key, dbtFilesBucketKey, fmt.Sprintf("%s/", EFS_MOUNT_PATH))

		file, err := os.Create(filepath)
		if err != nil {
			log.Fatalf("Could not create file: %v", err)
		}
		defer file.Close()

		downloader := manager.NewDownloader(s3Client)
		numBytes, err := downloader.Download(context.TODO(), file, &s3.GetObjectInput{
			Bucket: aws.String(dbtFilesBucketName),
			Key:    aws.String(*o.Key),
		})
		if err != nil {
			log.Fatalf("Failed to download S3 file: %v", err)
		}
		log.Print(numBytes)
	}

	return nil
}

func GenerateDbtProfile() error {
	secret := GetSecret()

	profile := Profile{
		Project: Project{
			Target: "env",
			Outputs: Outputs{
				Config: Config{
					Type:     "postgres",
					Host:     secret.Host,
					User:     "root",
					Password: secret.Password,
					Port:     5432,
					Dbname:   "circulatedb",
					Schema:   "cs",
					Threads:  4,
				},
			},
		},
	}

	data, err := yaml.Marshal(&profile)
	if err != nil {
		log.Fatal(err)
	}

	err2 := ioutil.WriteFile(fmt.Sprintf("%s/", EFS_MOUNT_PATH), data, 0644)
	if err2 != nil {
		log.Fatal(err2)
	}

	return nil
}

func HandleRequest(lambdaCtx context.Context) string {
	ConfigS3()

	dbtFilesBucketName := os.Getenv("AWS_S3_DATA_LAKE_IAC_BUCKET")
	dbtFilesBucketKey := os.Getenv("AWS_S3_DATA_LAKE_IAC_KEY")

	err := StoreDbtObjects(context.Background(), dbtFilesBucketName, dbtFilesBucketKey)
	if err != nil {
		log.Printf("Error writing to EFS: %v", err)
	}

	// folder := "/tmp"
	// filepath := filepath.Join(folder, filename)

	// file, err := os.Create(filepath)
	// if err != nil {
	// 	log.Fatalf("Could not create file: %v", err)
	// }
	// defer file.Close()

	// downloader := manager.NewDownloader(s3Client)
	// numBytes, err := downloader.Download(context.TODO(), file, &s3.GetObjectInput{
	// 	Bucket: aws.String(dbtFilesBucketName),
	// 	Key:    aws.String(dbtFilesBucketKey),
	// })
	// if err != nil {
	// 	log.Fatalf("Failed to download S3 file: %v", err)
	// }

	// keyList := []string{}

	// session, err := session.NewSession(&aws.Config{Region: aws.String(AWS_S3_REGION)})
	// if err != nil {
	// 	log.Fatal(err)
	// }

	return "Success"

}

func main() {
	lambda.Start(HandleRequest)
}
