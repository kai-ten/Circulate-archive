For swagger v2.0, use go-swagger
For OpenAPI v3, use oapi-codegen

swagger generate server [-f ./swagger.json] -A [application-name [--principal [principal-name]]
swagger generate server ./okta/spec.son -A okta

swagger generate server ./okta/spec.json -A okta
swagger generate client ./okta/spec.json -A okta

