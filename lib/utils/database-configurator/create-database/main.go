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
		createDbSchema := `
			CREATE SCHEMA IF NOT EXISTS cs;
		`
		_, err := tx.Exec(context.Background(), createDbSchema)
		if err != nil {
			log.Fatalf("Create database: %v", err)
		}

		return nil
	})

	if err == nil {
		log.Println("DB Schema creation complete.")
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
