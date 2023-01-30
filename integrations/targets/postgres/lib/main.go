package main

import (
	"bytes"
	"compress/gzip"
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/feature/s3/manager"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-secretsmanager-caching-go/secretcache"
	"github.com/jackc/pgx/v5"
)

type Secret struct {
	Username string `json:"username"`
	Password string `json:"password"`
	Engine   string `json:"engine"`
	Host     string `json:"host"`
}

type Request struct {
	KeyList []string
}

type PostgresObject struct {
	S3File   string
	FileMD5  string
	FileData []byte
	LoadDate time.Time
}

var (
	secretCache, _ = secretcache.New()
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

// These links help describe the method
// https://blog.devgenius.io/performing-bulk-insert-using-pgx-and-copyfrom-ce34c8b12bac
// https://github.com/jackc/pgx/issues/992

// ON CONFLICT (s3_file) DO NOTHING, must add unique to s3_file
func InsertFile(ctx context.Context, tx pgx.Tx, pgObj PostgresObject) error {
	_, err := tx.Exec(context.Background(), `
	INSERT INTO cs.lnd_okta_user (
		s3_file,
		file_md5,
		file_data,
		load_dt
	) VALUES ($1, $2, $3, $4);
	`, pgObj.S3File, pgObj.FileMD5, pgObj.FileData, pgObj.LoadDate)
	if err != nil {
		log.Fatalf("Unable to insert user: %v\n", err)
	}

	return nil
}

// Refactor this method into multiple smaller methods, where the struct is built as a result of the smaller methods.
func ProcessFile(ctx context.Context, tx pgx.Tx, key string) error {
	s3TempBucketName := os.Getenv("AWS_S3_SFN_TMP_BUCKET")
	var postgresObj PostgresObject

	postgresObj.S3File = key
	postgresObj.LoadDate = time.Now()

	headObj := s3.HeadObjectInput{
		Bucket: aws.String(s3TempBucketName),
		Key:    aws.String(key),
	}
	result, err := s3Client.HeadObject(context.Background(), &headObj)
	if err != nil {
		log.Fatalf("Could not read S3 header: %v", err)
	}

	postgresObj.FileMD5 = strings.Trim(*result.ETag, "\"")

	s := strings.Split(key, "/")
	filename := s[len(s)-1]
	folder := "/tmp"
	filepath := filepath.Join(folder, filename)

	file, err := os.Create(filepath)
	if err != nil {
		log.Fatalf("Could not create file: %v", err)
	}
	defer file.Close()

	downloader := manager.NewDownloader(s3Client)
	numBytes, err := downloader.Download(context.TODO(), file, &s3.GetObjectInput{
		Bucket: aws.String(s3TempBucketName),
		Key:    aws.String(key),
	})
	if err != nil {
		log.Fatalf("Failed to download S3 file: %v", err)
	}

	if numBytes > 0 {
		fileBytes, _ := os.ReadFile(filepath)
		gr, err := gzip.NewReader(bytes.NewBuffer(fileBytes))
		if err != nil {
			log.Fatalf("Could not unzip file: %v", err)
		}
		data, err := ioutil.ReadAll(gr)
		if err != nil {
			log.Fatalf("Could not read file: %v", err)
		}
		postgresObj.FileData = data
	}

	InsertFile(context.Background(), tx, postgresObj)

	return nil
}

func DbTx(ctx context.Context, conn *pgx.Conn, keyList []string) error {
	err := pgx.BeginTxFunc(context.Background(), conn, pgx.TxOptions{}, func(tx pgx.Tx) error {
		for _, key := range keyList {
			return ProcessFile(context.Background(), tx, key)
		}
		return nil
	})
	if err == nil {
		log.Println("Users insert completed.")
	} else {
		log.Fatal("error: ", err)
	}

	return nil
}

func HandleRequest(lambdaCtx context.Context, data Request) {
	ConfigS3()

	database_secret := os.Getenv("DATABASE_SECRET")
	secret, _ := secretCache.GetSecretString(database_secret)

	var secret_result Secret
	json.Unmarshal([]byte(secret), &secret_result)
	encodedPassword := url.QueryEscape(secret_result.Password)

	dsn := fmt.Sprintf("postgres://%s:%s@%s/circulatedb", secret_result.Username, encodedPassword, secret_result.Host)

	// TODO: https://github.com/jackc/pgx/wiki/Getting-started-with-pgx#using-a-connection-pool
	// Use RDS Proxy to assist with this
	// https://github.com/jackc/pgx/issues/923
	conn, err := pgx.Connect(context.Background(), dsn)
	if err != nil {
		log.Fatal("Failed to connect database", err)
	}
	defer conn.Close(context.Background())

	keyList := data.KeyList

	if len(keyList) > 0 {
		DbTx(context.Background(), conn, data.KeyList)
	}
}

func main() {
	lambda.Start(HandleRequest)
}
