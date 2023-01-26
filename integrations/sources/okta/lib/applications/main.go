package main

import (
	"bytes"
	"compress/gzip"
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-secretsmanager-caching-go/secretcache"
	"github.com/google/uuid"
	"github.com/okta/okta-sdk-golang/v2/okta"
)

type Secret struct {
	OktaDomain string `json:"okta_domain"`
	OktaApiKey string `json:"okta_api_key"`
}

type Response struct {
	KeyList []string
}

var (
	secretCache, _ = secretcache.New()
)

const (
	YYYYMMDD = "2006-01-02"
)

var (
	AWS_S3_REGION         = os.Getenv("AWS_S3_REGION")
	AWS_S3_SFN_TMP_BUCKET = os.Getenv("AWS_S3_SFN_TMP_BUCKET")
	SERVICE               = os.Getenv("CIRCULATE_SERVICE")
	ENDPOINT              = os.Getenv("CIRCULATE_ENDPOINT")
)

func GetSecret() (secret Secret) {
	api_secret := os.Getenv("API_SECRETS")
	secret_string, err := secretCache.GetSecretString(api_secret)
	if err != nil {
		log.Fatalf("Error retrieving secret: %v", err)
	}

	var secret_result Secret
	json.Unmarshal([]byte(secret_string), &secret_result)

	return secret_result
}

func Compress(data []byte) ([]byte, error) {
	var compressed bytes.Buffer
	w := gzip.NewWriter(&compressed)
	if _, err := w.Write(data); err != nil {
		return nil, err
	}
	if err := w.Close(); err != nil {
		return nil, err
	}
	return compressed.Bytes(), nil
}

func UploadFile(context context.Context, session *session.Session, data []byte) string {

	if !bytes.Equal(data, []byte("[]")) && data != nil {

		compressed, err := Compress(data)
		if err != nil {
			fmt.Println("Error:", err)
		}

		now := time.Now().UTC()
		date := now.Format(YYYYMMDD)
		s3UploadKey := SERVICE + "/" + ENDPOINT + "/date=" + date + "/hour=" + strconv.Itoa(now.Hour()) + "/" + uuid.NewString() + ".json.gz"

		_, err = s3.New(session).PutObject(&s3.PutObjectInput{
			Bucket:               aws.String(AWS_S3_SFN_TMP_BUCKET),
			Key:                  aws.String(s3UploadKey),
			ACL:                  aws.String("private"),
			Body:                 bytes.NewReader(compressed),
			ContentLength:        aws.Int64(int64(len(compressed))),
			ContentType:          aws.String("application/json"),
			ContentEncoding:      aws.String("gzip"),
			ContentDisposition:   aws.String("attachment"),
			ServerSideEncryption: aws.String("AES256"),
		})
		if err != nil {
			log.Fatalf("Could not upload file to S3: %v", err)
		}
		return s3UploadKey
	}

	return ""
}

func HandleRequest(lambdaCtx context.Context) (Response, error) {

	keyList := []string{}

	session, err := session.NewSession(&aws.Config{Region: aws.String(AWS_S3_REGION)})
	if err != nil {
		log.Fatal(err)
	}

	secret := GetSecret()
	apiToken := secret.OktaApiKey
	oktaDomain := secret.OktaDomain

	ctx, client, err := okta.NewClient(
		context.TODO(),
		okta.WithOrgUrl(oktaDomain),
		okta.WithToken(apiToken),
	)

	if err != nil {
		log.Printf("Error connecting to Okta Client: %v\n", err)
	}

	apps, resp, err := client.Application.ListApplications(ctx, nil)
	if err != nil {
		fmt.Printf("Error Getting Applications: %v\n", err)
	}

	if len(apps) == 0 {
		log.Fatal("No applications were returned in the response")
	}

	jsonObj, err := json.Marshal(apps)

	if err != nil {
		log.Fatalf("Error marshalling applications")
	}

	// Upload first page
	s3UploadKey := UploadFile(context.Background(), session, jsonObj)
	if s3UploadKey != "" {
		keyList = append(keyList, s3UploadKey)
	}

	hasNextPage := resp.HasNextPage() // what value is this? /type bool

	for hasNextPage {
		var nextObjSet []*okta.Application
		resp, err = resp.Next(ctx, &nextObjSet)
		if err != nil {
			log.Fatalf("Okta results nextPage: %v", err)
		}
		nextJsonObj, err := json.Marshal(nextObjSet)
		if err != nil {
			log.Fatalf("Error marshalling object")
		}

		// Upload n page
		nextS3UploadKey := UploadFile(context.Background(), session, nextJsonObj)
		if nextS3UploadKey != "" {
			keyList = append(keyList, nextS3UploadKey)
		}

		hasNextPage = resp.HasNextPage()
	}

	return Response{keyList}, nil
}

func main() {
	lambda.Start(HandleRequest)
}
