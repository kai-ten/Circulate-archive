inputs = {
  name = "circulate"
  env = "dev"

  sources = {
    okta = [
      {
        enabled = true
        endpoint = "users"
        source_path = "${get_repo_root()}/lib/okta/users/"
      },
      {
        enabled = true
        endpoint = "applications"
        source_path = "${get_repo_root()}/lib/okta/applications/"
      }
    ]
  }

  targets = {
    s3 = [
      {
        enabled = true
        endpoint = "s3"
      }
    ]
  }

  unions = {

  }
}