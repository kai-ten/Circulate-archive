inputs = {
  name = "circulate"
  env = "dev"

  sources = {
    okta = [
      {
        endpoint = "users"
        enabled = true
        source_path = "${get_repo_root()}/lib/okta/users/"
      },
      {
        endpoint = "applications"
        enabled = true
        source_path = "${get_repo_root()}/lib/okta/applications/"
      }
    ]
  }

  targets = {
    s3 = [
      {
        endpoint = "s3"
        enabled = true
      }
    ],
    postgres = [
      {
        endpoint = "postgres"
        enabled = false
      }
    ]
  }

  unions = {

  }
}