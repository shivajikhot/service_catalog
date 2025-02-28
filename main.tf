provider "aws" {
  region = "us-east-1" # Change to your region
}

# Step 1: Create IAM Policy for Launch Role
resource "aws_iam_policy" "s3_servicecatalog_policy" {
  name        = "S3ResourceCreationAndArtifactAccessPolicy"
  description = "Policy to allow Service Catalog access to create S3 resources"
  policy      = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": "s3:GetObject",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "s3:ExistingObjectTag/servicecatalog:provisioning": "true"
                }
            }
        },
        {
            "Action": [
                "s3:CreateBucket",
                "s3:DeleteBucket",
                "s3:Get*",
                "s3:List*",
                "s3:PutBucketTagging"
            ],
            "Resource": "arn:aws:s3:::*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "resource-groups:CreateGroup",
                "resource-groups:ListGroupResources",
                "resource-groups:DeleteGroup",
                "resource-groups:Tag"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "tag:GetResources",
                "tag:GetTagKeys",
                "tag:GetTagValues",
                "tag:TagResources",
                "tag:UntagResources"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
POLICY
}
# Step 2: Create IAM Role for Launch Constraint
resource "aws_iam_role" "servicecatalog_launch_role" {
  name               = "SCLaunch-S3product"
  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "GivePermissionsToServiceCatalog",
            "Effect": "Allow",
            "Principal": {
                "Service": "servicecatalog.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        },
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${var.account_id}:root"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringLike": {
                    "aws:PrincipalArn": [
                        "arn:aws:iam::${var.account_id}:role/TerraformEngine/TerraformExecutionRole*",
                        "arn:aws:iam::${var.account_id}:role/TerraformEngine/ServiceCatalogExternalParameterParserRole*",
                        "arn:aws:iam::${var.account_id}:role/TerraformEngine/ServiceCatalogTerraformOSParameterParserRole*"
                    ]
                }
            }
        }
    ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.servicecatalog_launch_role.name
  policy_arn = aws_iam_policy.s3_servicecatalog_policy.arn
}


# Step 3: Create AWS Service Catalog Portfolio
resource "aws_servicecatalog_portfolio" "s3_portfolio" {
  name        = "S3 bucket"
  description = "Sample portfolio for Terraform configurations"
  provider_name = "IT (it@example.com)"
}

# Step 4: Create AWS Service Catalog Product (External Product Type)
resource "aws_servicecatalog_product" "s3_product" {
  name        = "Simple S3 bucket"
  owner       = "IT"
  description = "Terraform product containing an Amazon S3 bucket."
  distributor = ""
  type        = "EXTERNAL"

  provisioning_artifact_parameters {
    name        = "v1.0"
    description = "Base Version"
    template_url = "https://terraform-backend-statefil.s3.us-east-1.amazonaws.com/s3bucket.tar.gz" # Update with your S3 URL
  }

  support_description = "Contact the IT department for issues deploying or connecting to this product."
  support_email       = "ITSupport@example.com"
  support_url         = "https://wiki.example.com/IT/support"
}

# Step 5: Associate Product with Portfolio
resource "aws_servicecatalog_product_portfolio_association" "s3_product_association" {
  portfolio_id = aws_servicecatalog_portfolio.s3_portfolio.id
  product_id   = aws_servicecatalog_product.s3_product.id
}

# Step 6: Add Launch Constraint
resource "aws_servicecatalog_constraint" "s3_launch_constraint" {
  portfolio_id = aws_servicecatalog_portfolio.s3_portfolio.id
  product_id   = aws_servicecatalog_product.s3_product.id
  type         = "LAUNCH"

  parameters = jsonencode({
    "RoleArn" = aws_iam_role.sc_launch_role.arn
  })
}
