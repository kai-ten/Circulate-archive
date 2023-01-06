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

// These links help describe the method
// https://blog.devgenius.io/performing-bulk-insert-using-pgx-and-copyfrom-ce34c8b12bac
// https://github.com/jackc/pgx/issues/992
func upsertUsers(ctx context.Context, tx pgx.Tx, client okta.Client, users []*okta.User) error {

	createTemp := `
		CREATE TEMPORARY TABLE temp_okta_users(
			LIKE "cs"."okta_user" INCLUDING ALL
		) ON COMMIT DROP;
	`

	_, err := tx.Exec(context.Background(), createTemp)
	if err != nil {
		log.Fatalf("Create temp table: %v", err)
	}

	usersCount := len(users)
	if usersCount == 0 {
		log.Fatal("Users array length cannot be 0")
	}

	copyCount, queryErr := tx.CopyFrom(
		context.Background(),
		pgx.Identifier{"temp_okta_users"},
		[]string{"id", "created", "email", "first_name"},
		pgx.CopyFromSlice(usersCount, func(i int) ([]interface{}, error) {
			user := users[i]
			userProfileStr, err := json.Marshal(user.Profile)
			if err != nil {
				log.Fatal(err)
			}

			var userProfile Profile
			if err := json.Unmarshal(userProfileStr, &userProfile); err != nil {
				log.Fatal(err)
			}

			return []interface{}{
				user.Id,
				user.Created,
				userProfile.Email,
				userProfile.FirstName,
			}, nil
		}),
	)

	if queryErr != nil {
		log.Fatalf("Error yo: %v", queryErr)
	}

	if int(copyCount) != usersCount {
		log.Fatal("Copied rows does not equal the size of the users array")
	}

	if _, err := tx.Exec(ctx,
		`INSERT INTO cs.okta_user (
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
		)
		SELECT
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
		FROM temp_okta_users ON CONFLICT (id) DO UPDATE SET
			created = excluded.created,
			activated = excluded.activated,
			status = excluded.status,
			status_changed = excluded.status_changed,
			last_login = excluded.last_login,
			last_updated = excluded.last_updated,
			password_changed = excluded.password_changed,
			login = excluded.login,
			first_name = excluded.first_name,
			last_name = excluded.last_name,
			email = excluded.email,
			email_verified = excluded.email_verified,
			second_email = excluded.second_email,
			second_email_verified = excluded.second_email_verified,
			phone = excluded.phone,
			phone_verified = excluded.phone_verified,
			second_phone = excluded.second_phone,
			second_phone_verified = excluded.second_phone_verified,
			display_name = excluded.display_name,
			nickname = excluded.nickname,
			profile_url = excluded.profile_url,
			title = excluded.title,
			user_type = excluded.user_type,
			preferred_language = excluded.preferred_language,
			perferred_timezone = excluded.perferred_timezone,
			locale = excluded.locale,
			timezone = excluded.timezone,
			organization = excluded.organization,
			cost_center = excluded.cost_center,
			department = excluded.department,
			division = excluded.division,
			employee_number = excluded.employee_number,
			employee_type = excluded.employee_type,
			manager = excluded.manager,
			manager_id = excluded.manager_id,
			primary_relationship = excluded.primary_relationship;
		`,
	); err != nil {
		return err
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
	users, _, err := client.User.ListUsers(ctx, nil)
	if err != nil {
		fmt.Printf("Error Getting Users: %v\n", err)
	}

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
