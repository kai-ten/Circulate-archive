package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/jackc/pgx/v5"
	"github.com/okta/okta-sdk-golang/v2/okta"
)

// Base Okta Profile fields - https://developer.okta.com/docs/reference/api/schemas/#user-profile-base-subschema
// TODO: Handle custom fields by orgs with a separate UI
type Profile struct {
	Login               string `json:"login"`
	FirstName           string `json:"firstName"`
	LastName            string `json:"lastName"`
	Email               string `json:"email"`
	EmailVerified       bool   `json:"emailVerified"`
	SecondEmail         string `json:"secondEmail"`
	SecondEmailVerified bool   `json:"secondEmailVerified"`
	Phone               string `json:"phone"`
	PhoneVerified       bool   `json:"phoneVerified"`
	SecondPhone         string `json:"secondPhone"`
	SecondPhoneVerified bool   `json:"secondPhoneVerified"`
	DisplayName         string `json:"displayName"`
	NickName            string `json:"nickName"`
	ProfileUrl          string `json:"profileUrl"`
	Title               string `json:"title"`
	UserType            string `json:"userType"`
	PreferredLanguage   string `json:"preferredLanguage"`
	PreferredTimeZone   string `json:"preferredTimeZone"`
	Locale              string `json:"locale"`
	TimeZone            string `json:"timeZone"`
	Organization        string `json:"organization"`
	CostCenter          string `json:"costCenter"`
	Department          string `json:"department"`
	Division            string `json:"division"`
	EmployeeNumber      string `json:"employeeNumber"`
	EmployeeType        string `json:"employeeType"`
	Manager             string `json:"manager"`
	ManagerId           string `json:"managerId"`
	PrimaryRelationship string `json:"primaryRelationship"`
}

func upsertUsers(ctx context.Context, tx pgx.Tx, client okta.Client, users []*okta.User) error {

	var parsedUsers [][]interface{}

	// How to convert struct to [][]any, then create temp table to handle inserts
	// https://blog.devgenius.io/performing-bulk-insert-using-pgx-and-copyfrom-ce34c8b12bac
	// https://github.com/jackc/pgx/issues/992

	for _, user := range users {
		userProfileStr, err := json.Marshal(user.Profile)
		if err != nil {
			log.Fatal(err)
		}

		var userProfile Profile
		if err := json.Unmarshal(userProfileStr, &userProfile); err != nil {
			log.Fatal(err)
		}

		parsedUsers = append(parsedUsers, []interface{}{
			user.Id,
			user.Created,
			userProfile.Email,
		})
	}

	copyCount, queryErr := tx.CopyFrom(
		context.Background(),
		pgx.Identifier{"cs", "okta_user"},
		[]string{"id", "created", "email"},
		pgx.CopyFromRows(parsedUsers),
	)

	if queryErr != nil {
		log.Fatal(queryErr)
	}

	if int(copyCount) != len(parsedUsers) {
		log.Fatal("Copied rows does not equal the size of the users array")
	}

	return nil
}

func handleRequest(lambdaCtx context.Context) {
	dsn := "postgres://root:TsyFzgSdGrEsWOoTn78E@circulate-postgresql.cfnt2r7lvj4b.us-east-2.rds.amazonaws.com:5432/circulatedb"

	// TODO: https://github.com/jackc/pgx/wiki/Getting-started-with-pgx#using-a-connection-pool
	// Use RDS Proxy to assist with this
	// https://github.com/jackc/pgx/issues/923
	conn, err := pgx.Connect(context.Background(), dsn)
	if err != nil {
		log.Fatal("Failed to connect database", err)
	}
	defer conn.Close(context.Background())

	apiToken := "00qSTBCo2QJiEvM_SHqZS3P0fBSgqySScCja3BKkv7"
	oktaDomain := "https://dev-52108562.okta.com"

	ctx, client, err := okta.NewClient(
		context.TODO(),
		okta.WithOrgUrl(oktaDomain),
		okta.WithToken(apiToken),
	)

	if err != nil {
		log.Printf("Error: %v\n", err)
	}

	// TODO: https://github.com/okta/okta-sdk-golang#pagination
	users, resp, err := client.User.ListUsers(ctx, nil)
	if err != nil {
		fmt.Printf("Error Getting Users: %v\n", err)
	}
	log.Printf("Response: %+v\n", resp)

	// Check and see if Okta Pagination has any more results here
	err = pgx.BeginTxFunc(context.Background(), conn, pgx.TxOptions{}, func(tx pgx.Tx) error {
		return upsertUsers(context.Background(), tx, *client, users)
	})
	if err == nil {
		log.Println("New rows created.")
	} else {
		log.Fatal("error: ", err)
	}

}

func main() {
	lambda.Start(handleRequest)
}
