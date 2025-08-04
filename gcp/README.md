# GCP Terraform module

## Usage

```t
module "datagrok_core" {
  # We recommend to specify an exact tag as ref argument
  source = "module/gcp/datagrog"

  name                = "datagrok"
  environment         = terraform.workspace
  domain_name         = "datagrok.example"
  # docker_hub_credentials = {
  #   create_secret = true
  #   user          = "exampleUser"
  #   password      = "examplePassword"
  # }
}
```

## Terraform

### Init

```sh
tf init
```

### Plan

```sh
tf plan
```

### Create resources

```sh
tf apply -auto-approve
```

### Destroy resources

```sh
tf apply -destroy -auto-approve
```

### !!! NOTES

Make ``` $ tf fmt ``` before commit changes to repository
