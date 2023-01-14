package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/url"
	"os"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-secretsmanager-caching-go/secretcache"
	"github.com/jackc/pgx/v5"
)

type Secret struct {
	Username string `json:"username"`
	Password string `json:"password"`
	Engine   string `json:"engine"`
	Host     string `json:"host"`
}

var (
	secretCache, _ = secretcache.New()
)

func dbTx(ctx context.Context, conn *pgx.Conn) error {
	err := pgx.BeginTxFunc(context.Background(), conn, pgx.TxOptions{}, func(tx pgx.Tx) error {
		createDbTable := `
		CREATE TABLE IF NOT EXISTS cs.okta_user (
			id VARCHAR(50) PRIMARY KEY,
			created TIMESTAMPTZ,
			activated TIMESTAMPTZ,
			status VARCHAR(50),
			status_changed TIMESTAMPTZ,
			last_login TIMESTAMPTZ,
			last_updated TIMESTAMPTZ,
			password_changed TIMESTAMPTZ,
			login VARCHAR(100),
			first_name VARCHAR(100),
			last_name VARCHAR(100),
			email VARCHAR(100),
			email_verified BOOL,
			second_email VARCHAR(100),
			second_email_verified BOOL,
			phone VARCHAR(100),
			phone_verified BOOL,
			second_phone VARCHAR(100),
			second_phone_verified BOOL,
			display_name TEXT,
			nickname TEXT,
			profile_url TEXT,
			title TEXT,
			user_type TEXT,
			preferred_language TEXT,
			perferred_timezone TEXT,
			locale TEXT,
			timezone TEXT,
			organization TEXT,
			cost_center TEXT,
			department TEXT,
			division TEXT,
			employee_number TEXT,
			employee_type TEXT,
			manager TEXT,
			manager_id TEXT,
			primary_relationship TEXT,
			UNIQUE(id, login, email, second_email)
		);

		CREATE INDEX IF NOT EXISTS okta_user_index
		ON cs.okta_user (
			login,
			created,
			last_updated
		);
		`
		_, err := tx.Exec(context.Background(), createDbTable)
		if err != nil {
			log.Fatalf("Create table: %v", err)
		}

		return nil
	})

	if err == nil {
		log.Println("DB Table creation complete.")
	} else {
		log.Fatal("error: ", err)
	}

	return nil
}

func handleRequest(lambdaCtx context.Context) {

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
		log.Fatal("Failed to connect database: ", err)
	}
	defer conn.Close(context.Background())

	dbTx(context.Background(), conn)

}

func main() {
	lambda.Start(handleRequest)
}
