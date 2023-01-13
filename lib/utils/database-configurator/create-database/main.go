package main

import (
	"context"
	"log"
	"os"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-secretsmanager-caching-go/secretcache"
)

var (
	secretCache, _ = secretcache.New()
)

// func dbTx(ctx context.Context, conn *pgx.Conn) error {
// 	err := pgx.BeginTxFunc(context.Background(), conn, pgx.TxOptions{}, func(tx pgx.Tx) error {
// 		log.Print("okok")
// 		createDbSchema := `
// 			CREATE DATABASE IF NOT EXISTS circulatedb;
// 			USE circulatedb;
// 			CREATE SCHEMA IF NOT EXISTS cs;
// 		`
// 		_, err := tx.Exec(context.Background(), createDbSchema)
// 		if err != nil {
// 			log.Fatalf("Create database: %v", err)
// 		}

// 		return nil
// 	})

// 	if err == nil {
// 		log.Println("DB Schema creation complete.")
// 	} else {
// 		log.Fatal("error: ", err)
// 	}

// 	log.Print("WO")

// 	return nil
// }

func handleRequest(lambdaCtx context.Context) {

	database_secret := os.Getenv("DATABASE_SECRET")
	log.Printf(database_secret)
	secret, _ := secretCache.GetSecretString(database_secret)
	log.Printf(secret)
	// encodedPassword := url.QueryEscape("ok")
	// dsn := fmt.Sprintf("postgres://%s:%s@%s/circulatedb", "username", encodedPassword, "host")

	// log.Print(dsn)

	// // TODO: https://github.com/jackc/pgx/wiki/Getting-started-with-pgx#using-a-connection-pool
	// // Use RDS Proxy to assist with this
	// // https://github.com/jackc/pgx/issues/923
	// conn, err := pgx.Connect(context.Background(), dsn)
	// if err != nil {
	// 	log.Fatal("Failed to connect database: ", err)
	// }
	// log.Print("LOSER")
	// defer conn.Close(context.Background())

	// log.Print("LOSER")

	// dbTx(context.Background(), conn)

}

func main() {
	lambda.Start(handleRequest)
}
