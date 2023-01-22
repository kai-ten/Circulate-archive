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

// filename TEXT COLLATE pg_catalog."default" NOT NULL,
// md5sum VARCHAR(40) COLLATE pg_catalog."default" NOT NULL,
// data jsonb NOT NULL,
// load_dt timestamp without time zone NOT NULL
type postgresObject struct {
	S3File   string
	FileID   string
	Data     []byte
	LoadDate time.Time
}

var (
	secretCache, _ = secretcache.New()
)

var s3Client *s3.Client

func configS3() {
	region := os.Getenv("AWS_REGION")
	cfg, err := config.LoadDefaultConfig(context.TODO(), config.WithRegion(region))
	if err != nil {
		log.Fatal(err)
	}

	s3Client = s3.NewFromConfig(cfg)
}

// // These links help describe the method
// // https://blog.devgenius.io/performing-bulk-insert-using-pgx-and-copyfrom-ce34c8b12bac
// // https://github.com/jackc/pgx/issues/992
// func upsertUsers(ctx context.Context, tx pgx.Tx, client okta.Client, users []*okta.User) error {

// 	createTemp := `
// 		CREATE TEMPORARY TABLE temp_okta_users(
// 			LIKE "cs"."okta_user" INCLUDING ALL
// 		) ON COMMIT DROP;
// 	`

// 	_, err := tx.Exec(context.Background(), createTemp)
// 	if err != nil {
// 		log.Fatalf("Create temp table: %v", err)
// 	}

// 	usersCount := len(users)
// 	if usersCount == 0 {
// 		log.Fatal("Users array length cannot be 0")
// 	}

// 	copyCount, queryErr := tx.CopyFrom(
// 		context.Background(),
// 		pgx.Identifier{"temp_okta_users"},
// 		[]string{
// 			"id", "created", "activated", "status", "status_changed", "last_login",
// 			"last_updated", "password_changed", "login", "first_name", "last_name", "email",
// 			"email_verified", "second_email", "second_email_verified", "phone", "phone_verified",
// 			"second_phone", "second_phone_verified", "display_name", "nickname", "profile_url",
// 			"title", "user_type", "preferred_language", "perferred_timezone", "locale", "timezone",
// 			"organization", "cost_center", "department", "division", "employee_number", "employee_type",
// 			"manager", "manager_id", "primary_relationship",
// 		},
// 		pgx.CopyFromSlice(usersCount, func(i int) ([]interface{}, error) {
// 			user := users[i]
// 			userProfileStr, err := json.Marshal(user.Profile)
// 			if err != nil {
// 				log.Fatal(err)
// 			}

// 			var userProfile Profile
// 			if err := json.Unmarshal(userProfileStr, &userProfile); err != nil {
// 				log.Fatal(err)
// 			}

// 			return []interface{}{
// 				user.Id,
// 				user.Created,
// 				user.Activated,
// 				user.Status,
// 				user.StatusChanged,
// 				user.LastLogin,
// 				user.LastUpdated,
// 				user.PasswordChanged,
// 				userProfile.Login,
// 				userProfile.FirstName,
// 				userProfile.LastName,
// 				userProfile.Email,
// 				userProfile.EmailVerified,
// 				userProfile.SecondEmail,
// 				userProfile.SecondEmailVerified,
// 				userProfile.Phone,
// 				userProfile.PhoneVerified,
// 				userProfile.SecondPhone,
// 				userProfile.SecondPhoneVerified,
// 				userProfile.DisplayName,
// 				userProfile.NickName,
// 				userProfile.ProfileUrl,
// 				userProfile.Title,
// 				userProfile.UserType,
// 				userProfile.PreferredLanguage,
// 				userProfile.PreferredTimeZone,
// 				userProfile.Locale,
// 				userProfile.TimeZone,
// 				userProfile.Organization,
// 				userProfile.CostCenter,
// 				userProfile.Department,
// 				userProfile.Division,
// 				userProfile.EmployeeNumber,
// 				userProfile.EmployeeType,
// 				userProfile.Manager,
// 				userProfile.ManagerId,
// 				userProfile.PrimaryRelationship,
// 			}, nil
// 		}),
// 	)

// 	if queryErr != nil {
// 		log.Fatalf("CopyFrom error: %v", queryErr)
// 	}

// 	if int(copyCount) != usersCount {
// 		log.Fatal("Copied rows does not equal the size of the users array")
// 	}

// 	if _, err := tx.Exec(ctx,
// 		`INSERT INTO cs.okta_user (
// 			id,
// 			created,
// 			activated,
// 			status,
// 			status_changed,
// 			last_login,
// 			last_updated,
// 			password_changed,
// 			login,
// 			first_name,
// 			last_name,
// 			email,
// 			email_verified,
// 			second_email,
// 			second_email_verified,
// 			phone,
// 			phone_verified,
// 			second_phone,
// 			second_phone_verified,
// 			display_name,
// 			nickname,
// 			profile_url,
// 			title,
// 			user_type,
// 			preferred_language,
// 			perferred_timezone,
// 			locale,
// 			timezone,
// 			organization,
// 			cost_center,
// 			department,
// 			division,
// 			employee_number,
// 			employee_type,
// 			manager,
// 			manager_id,
// 			primary_relationship
// 		)
// 		SELECT
// 			id,
// 			created,
// 			activated,
// 			status,
// 			status_changed,
// 			last_login,
// 			last_updated,
// 			password_changed,
// 			login,
// 			first_name,
// 			last_name,
// 			email,
// 			email_verified,
// 			second_email,
// 			second_email_verified,
// 			phone,
// 			phone_verified,
// 			second_phone,
// 			second_phone_verified,
// 			display_name,
// 			nickname,
// 			profile_url,
// 			title,
// 			user_type,
// 			preferred_language,
// 			perferred_timezone,
// 			locale,
// 			timezone,
// 			organization,
// 			cost_center,
// 			department,
// 			division,
// 			employee_number,
// 			employee_type,
// 			manager,
// 			manager_id,
// 			primary_relationship
// 		FROM temp_okta_users ON CONFLICT (id) DO UPDATE SET
// 			created = excluded.created,
// 			activated = excluded.activated,
// 			status = excluded.status,
// 			status_changed = excluded.status_changed,
// 			last_login = excluded.last_login,
// 			last_updated = excluded.last_updated,
// 			password_changed = excluded.password_changed,
// 			login = excluded.login,
// 			first_name = excluded.first_name,
// 			last_name = excluded.last_name,
// 			email = excluded.email,
// 			email_verified = excluded.email_verified,
// 			second_email = excluded.second_email,
// 			second_email_verified = excluded.second_email_verified,
// 			phone = excluded.phone,
// 			phone_verified = excluded.phone_verified,
// 			second_phone = excluded.second_phone,
// 			second_phone_verified = excluded.second_phone_verified,
// 			display_name = excluded.display_name,
// 			nickname = excluded.nickname,
// 			profile_url = excluded.profile_url,
// 			title = excluded.title,
// 			user_type = excluded.user_type,
// 			preferred_language = excluded.preferred_language,
// 			perferred_timezone = excluded.perferred_timezone,
// 			locale = excluded.locale,
// 			timezone = excluded.timezone,
// 			organization = excluded.organization,
// 			cost_center = excluded.cost_center,
// 			department = excluded.department,
// 			division = excluded.division,
// 			employee_number = excluded.employee_number,
// 			employee_type = excluded.employee_type,
// 			manager = excluded.manager,
// 			manager_id = excluded.manager_id,
// 			primary_relationship = excluded.primary_relationship;
// 		`,
// 	); err != nil {
// 		return err
// 	}

// 	return nil
// }

func dbTx(ctx context.Context, conn *pgx.Conn, keyList []string) error {
	err := pgx.BeginTxFunc(context.Background(), conn, pgx.TxOptions{}, func(tx pgx.Tx) error {
		// return upsertUsers(context.Background(), tx, client, users)
		return processFiles(context.Background(), tx, keyList)
	})
	if err == nil {
		log.Println("Users upsert completed.")
	} else {
		log.Fatal("error: ", err)
	}

	return nil
}

func processFiles(ctx context.Context, tx pgx.Tx, keyList []string) error {
	for _, key := range keyList {
		s3BucketName := os.Getenv("S3_BUCKET")
		var postgresObj postgresObject

		postgresObj.S3File = key
		postgresObj.LoadDate = time.Now()

		log.Print(key)

		headObj := s3.HeadObjectInput{
			Bucket: aws.String(s3BucketName),
			Key:    aws.String(key),
		}
		log.Print(headObj)
		result, err := s3Client.HeadObject(context.Background(), &headObj)
		if err != nil {
			log.Fatalf("Could not read S3 header: %v", err)
		}

		log.Print("here")

		s := strings.Split(key, "/")
		filename := s[len(s)-1]
		folder := "/tmp"
		filepath := filepath.Join(folder, filename)

		log.Print(filename)

		file, err := os.Create(filepath)
		if err != nil {
			log.Fatalf("Could not create file: %v", err)
		}
		defer file.Close()

		log.Print("here")

		postgresObj.FileID = *result.ETag

		downloader := manager.NewDownloader(s3Client)
		numBytes, err := downloader.Download(context.TODO(), file, &s3.GetObjectInput{
			Bucket: aws.String(s3BucketName),
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
			postgresObj.Data = data
		}

		log.Print(postgresObj)
		// dbTx(context.Background(), conn, *client, users)
	}
	return nil
}

func handleRequest(lambdaCtx context.Context, data Request) {

	log.Print(data.KeyList)
	configS3()
	log.Print("MADE IT HERE")

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

	// Download S3 File(s)
	// For each S3 file, gz unzip, convert json to bytes, and write to postgres

	dbTx(context.Background(), conn, data.KeyList)

}

func main() {
	lambda.Start(handleRequest)
}
