package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	"github.com/aws/aws-lambda-go/lambda"
	"github.com/cockroachdb/cockroach-go/v2/crdb/crdbpgx"
	"github.com/jackc/pgx/v4"
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

	for index, user := range users {
		fmt.Printf("User %d: %+v\n", index, user)

		user, resp, err := client.User.GetUser(ctx, user.Id)
		if err != nil {
			fmt.Printf("Error Getting User: %v\n", err)
		}
		fmt.Printf("User: %+v\n Response: %+v\n\n", user.Profile, resp)

		userProfileStr, err := json.Marshal(user.Profile)
		if err != nil {
			log.Fatal(err)
		}

		var userProfile Profile
		if err := json.Unmarshal(userProfileStr, &userProfile); err != nil {
			log.Fatal(err)
		}

		fmt.Printf("NULL?? %v\n", user.Activated)

		if _, err := tx.Exec(ctx,
			`UPSERT INTO cs.okta_user (
				id,
				created,
				activated,
				status,
				status_changed,
				last_login,
				last_updated,
				password_changed,
				login,
				first_name,
				last_name,
				email,
				email_verified,
				second_email,
				second_email_verified,
				phone,
				phone_verified,
				second_phone,
				second_phone_verified,
				display_name,
				nickname,
				profile_url,
				title,
				user_type,
				preferred_language,
				perferred_timezone,
				locale,
				timezone,
				organization,
				cost_center,
				department,
				division,
				employee_number,
				employee_type,
				manager,
				manager_id,
				primary_relationship
			) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37)`,
			user.Id,
			user.Created,
			user.Activated,
			user.Status,
			user.StatusChanged,
			user.LastLogin,
			user.LastUpdated,
			user.PasswordChanged,
			userProfile.Login,
			userProfile.FirstName,
			userProfile.LastName,
			userProfile.Email,
			userProfile.EmailVerified,
			userProfile.SecondEmail,
			userProfile.SecondEmailVerified,
			userProfile.Phone,
			userProfile.PhoneVerified,
			userProfile.SecondPhone,
			userProfile.SecondPhoneVerified,
			userProfile.DisplayName,
			userProfile.NickName,
			userProfile.ProfileUrl,
			userProfile.Title,
			userProfile.UserType,
			userProfile.PreferredLanguage,
			userProfile.PreferredTimeZone,
			userProfile.Locale,
			userProfile.TimeZone,
			userProfile.Organization,
			userProfile.CostCenter,
			userProfile.Department,
			userProfile.Division,
			userProfile.EmployeeNumber,
			userProfile.EmployeeType,
			userProfile.Manager,
			userProfile.ManagerId,
			userProfile.PrimaryRelationship,
		); err != nil {
			return err
		}

	}

	// Insert four rows into the "accounts" table.
	log.Println("Creating new rows...")

	return nil
}

func handleRequest(lambdaCtx context.Context) {
	dsn := "postgresql://kai:-DH0WZpUL6PajyBSa9oqLg@bamboo-scylla-7752.7tt.cockroachlabs.cloud:26257/Circulate?sslmode=verify-full"
	ctx := context.Background()
	conn, err := pgx.Connect(ctx, dsn)
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
		okta.WithRequestTimeout(45),
		okta.WithRateLimitMaxRetries(3),
	)

	if err != nil {
		fmt.Printf("Error: %v\n", err)
	}

	users, resp, err := client.User.ListUsers(ctx, nil)
	if err != nil {
		fmt.Printf("Error Getting Users: %v\n", err)
	}
	fmt.Printf("Users: %+v\n Response: %+v\n\n", users, resp)

	err = crdbpgx.ExecuteTx(context.Background(), conn, pgx.TxOptions{}, func(tx pgx.Tx) error {
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
