terraform {
  required_version = ">= 0.12.1"
  backend "s3" {}
}

provider "aws" {
  version = "~> 2.7"
}

variable "bucket" {}
variable "role" {}

variable "allow_ecr" {
  default = ""
}

locals {
  # avoid max-len 63,
  # we also want to replace dots in domain name with dashes
  role1 = "${substr("${replace(lower(var.role), ".", "-")}",0, min(length("${var.role}"), 63))}"
  # avoid max-len 63, excluding postfix that looks like 20190701100159861000000001
  role2 = "${substr("${replace(lower(var.role), ".", "-")}",0, min(length("${var.role}"), 36))}"
}

data "aws_s3_bucket" "selected" {
  bucket = "${var.bucket}"
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy" "bucket_allow_rw" {
  name_prefix = "${local.role2}"
  role        = "${aws_iam_role.main.id}"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:ListBucket"
      ],
     "Resource": [
        "${data.aws_s3_bucket.selected.arn}"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:DeleteObject",
        "s3:PutObjectAcl"
      ],
      "Resource": [
         "${data.aws_s3_bucket.selected.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetBucketLocation",
        "s3:ListAllMyBuckets"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "ecr_allow_pullpush" {
  name_prefix = "${local.role2}"
  count       = "${var.allow_ecr ? 1 : 0}"
  role        = "${aws_iam_role.main.id}"
  policy      = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "ecr:CompleteLayerUpload",
        "ecr:GetAuthorizationToken",
        "ecr:GetDownloadUrlForLayer",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:UploadLayerPart"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "main" {
  name = "${local.role1}"
  description = "Trust to kubeflow application to access cloud"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    },
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        ]
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

output "assume_role_arn" {
  value = "${aws_iam_role.main.arn}"
}
