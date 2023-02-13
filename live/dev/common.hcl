inputs = {
  name = "circulate"
  env = "dev"

  sources = {
    okta = [
      {
        endpoint = "users"
        source_path = "${get_repo_root()}/lib/okta/users/"
      },
      {
        endpoint = "applications"
        source_path = "${get_repo_root()}/lib/okta/applications/"
      }
    ]
  }

  targets = {

  }

  unions = {

  }
}