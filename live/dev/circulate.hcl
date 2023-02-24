inputs = {
  name = "circulate"
  env = "dev"

  sources = {
    okta = [
      {
        endpoint = "users"
        enabled = true
        src_path = "${get_repo_root()}/lib/sources/okta/users/"
      },
      {
        endpoint = "applications"
        enabled = true
        src_path = "${get_repo_root()}/lib/sources/okta/applications/"
      }
    ]
  }

  targets = {
    s3 = [
      {
        endpoint = "s3"
        enabled = true
        src_path = "${get_repo_root()}/lib/targets/s3/"
      }
    ],
    postgres = [
      {
        endpoint = "postgres"
        enabled = false
        src_path = "${get_repo_root()}/lib/targets/postgres/"
      }
    ]
  }

  unions = {
    okta_users_s3 = [
      {
        source = "okta_users"
        target = "s3"
        transform = disabled
      }
    ]
  }
}