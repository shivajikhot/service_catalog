terraform {
  backend "s3" {
    bucket         = "terraform-backend-statefil"  
    key            = "Service_catalog/development/terraform.tfstate"
    region         = "us-east-1"            
    encrypt        = true
  }
}
