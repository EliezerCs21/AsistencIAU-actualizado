terraform {
  backend "s3" {
    bucket       = "tfstate-eliezer-asistenciau-2026"
    key          = "asistenciau/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}