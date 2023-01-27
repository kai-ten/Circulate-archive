package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

type Request struct {
	KeyList []string
}

var s3Client *s3.Client

var sourceBucket = os.Getenv("SOURCE_BUCKET")
var targetBucket = os.Getenv("TARGET_BUCKET")

func ConfigS3() {
	region := os.Getenv("AWS_REGION")
	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(region))
	if err != nil {
		log.Fatal(err)
	}

	s3Client = s3.NewFromConfig(cfg)
}

// CopyToFolder copies an object in a bucket to a subfolder in the same bucket.
func CopyToS3Target(objectKey string) error {
	_, err := s3Client.CopyObject(context.TODO(), &s3.CopyObjectInput{
		Bucket:     aws.String(targetBucket),
		CopySource: aws.String(fmt.Sprintf("%v/%v", sourceBucket, objectKey)),
		Key:        aws.String(objectKey),
	})
	if err != nil {
		log.Fatalf("Error: Couldn't copy object from %v:%v to %v:%v. Here's why: %v\n",
			sourceBucket, objectKey, targetBucket, objectKey, err)
	}
	return err
}

func HandleRequest(lambdaCtx context.Context, data Request) {
	ConfigS3()

	keyList := data.KeyList

	for _, key := range keyList {
		CopyToS3Target(key)
	}
}

func main() {
	lambda.Start(HandleRequest)
}
