package main

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
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

func StoreDbtObjects(ctx context.Context, dbtFilesBucketName string, dbtFilesBucketKey string) error {

	log.Printf("Bucketname: %v, Bucketfilekey: %v", dbtFilesBucketName, dbtFilesBucketKey)

	input := &s3.ListObjectsV2Input{
		Bucket: &dbtFilesBucketName,
		Prefix: &dbtFilesBucketKey,
	}

	o, err := s3Client.ListObjectsV2(context.Background(), input)
	if err != nil {
		log.Fatalf("Error listing objects")
		return err
	}

	log.Println(o.Contents)

	for _, o := range o.Contents {
		// e.g. bucket-name/api/okta/users/dbt/models/staging/okta_users.sql -> /mnt/okta-users-dbt/okta-users-dbt/models/staging/okta_users.sql
		fp := strings.ReplaceAll(*o.Key, dbtFilesBucketKey, "/mnt/okta-users-dbt/")
		// s3://circulate-dev-iac
		// /api/okta/users/dbt/logs/dbt.log

		log.Printf("Old Key: %v", *o.Key)
		log.Printf("New Key: %v", fp)

		if _, err := os.Stat(fp); os.IsNotExist(err) {
			os.MkdirAll(filepath.Dir(fp), os.ModePerm)
		}

		file, err := os.Create(fp)
		if err != nil {
			log.Fatalf("Could not create file: %v", err)
		}
		defer file.Close()

		downloader := manager.NewDownloader(s3Client)
		if _, err := downloader.Download(context.TODO(), file, &s3.GetObjectInput{
			Bucket: aws.String(dbtFilesBucketName),
			Key:    aws.String(*o.Key),
		}); err != nil {
			log.Fatalf("Failed to download S3 file: %v", err)
		}
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
					Host:     "circulate-dev.cfnt2r7lvj4b.us-east-2.rds.amazonaws.com",
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
		log.Fatalf("Failed to serialize to yaml: %v", err)
	}

	err2 := ioutil.WriteFile("/mnt/okta-users-dbt/"+"profiles.yml", data, 0644)
	if err2 != nil {
		log.Fatal(err2)
	}

	return nil
}

func HandleRequest(lambdaCtx context.Context) {
	ConfigS3()

	dbtFilesBucketName := os.Getenv("AWS_S3_DATA_LAKE_IAC_BUCKET")
	dbtFilesBucketKey := os.Getenv("AWS_S3_DATA_LAKE_IAC_KEY")

	os.RemoveAll("/mnt/okta-users-dbt")
	err := StoreDbtObjects(context.Background(), dbtFilesBucketName, dbtFilesBucketKey)

	if err != nil {
		log.Printf("Error writing to EFS: %v", err)
	}

	err1 := GenerateDbtProfile()
	if err != nil {
		log.Fatalf("Could not generate dbt profile: %v", err1)
	}

	// so the mounting is working
	err2 := filepath.Walk("/mnt/okta-users-dbt/", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			fmt.Println(err)
			return err
		}
		fmt.Printf("dir: %v: name: %s\n", info.IsDir(), path)
		return nil
	})
	if err2 != nil {
		fmt.Println(err)
	}

	log.Println(dbtFilesBucketKey)
	log.Println(EFS_MOUNT_PATH)
	log.Println("WPOKDSKLD")

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

}

func main() {
	lambda.Start(HandleRequest)
}
