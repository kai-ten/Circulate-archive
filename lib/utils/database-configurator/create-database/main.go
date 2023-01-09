package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/jackc/pgx/v5"
)

func dbTx(ctx context.Context, conn *pgx.Conn) error {
	err := pgx.BeginTxFunc(context.Background(), conn, pgx.TxOptions{}, func(tx pgx.Tx) error {

		createDbSchema := `
			CREATE DATABASE IF NOT EXISTS circulatedb;
			USE circulatedb;
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

	log.Print("WO")

	return nil
}

func handleRequest(lambdaCtx context.Context) {
	host := os.Getenv("DB_CLIENT")
	username := os.Getenv("DB_USER")
	password := os.Getenv("DB_PASS")
	dsn := fmt.Sprintf("postgres://%s:%s@%s/circulatedb", username, password, host)

	// TODO: https://github.com/jackc/pgx/wiki/Getting-started-with-pgx#using-a-connection-pool
	// Use RDS Proxy to assist with this
	// https://github.com/jackc/pgx/issues/923
	conn, err := pgx.Connect(context.Background(), dsn)
	if err != nil {
		log.Fatal("Failed to connect database", err)
	}
	defer conn.Close(context.Background())

	dbTx(context.Background(), conn)

}

func main() {
	lambda.Start(handleRequest)
}
