provider "aws" {
  region = var.region

  default_tags {
    tags = local.tags
  }
}

data "aws_caller_identity" "current" {}

locals {
  tags = {
    Project     = var.name
    Owner       = var.owner
    Environment = var.environment
    ManagedBy   = "terraform"
    Teardown    = "nightly"
  }

  bucket_name = "${var.name}-${data.aws_caller_identity.current.account_id}-${var.region}"
}

# ---------------------------------------------------------------- S3 (notes)

resource "aws_s3_bucket" "notes" {
  #checkov:skip=CKV_AWS_18:Access logging needs a second bucket; out of scope for a lab that is destroyed nightly.
  #checkov:skip=CKV_AWS_144:Cross-region replication is not needed for ephemeral lab data.
  #checkov:skip=CKV_AWS_145:SSE-S3 (AES256) is used on purpose; SSE-KMS adds cost and key-policy work for no gain here.
  #checkov:skip=CKV2_AWS_62:No event notifications are consumed.
  bucket        = local.bucket_name
  force_destroy = true # lets the nightly destroy empty a versioned bucket
}

resource "aws_s3_bucket_public_access_block" "notes" {
  bucket                  = aws_s3_bucket.notes.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "notes" {
  bucket = aws_s3_bucket.notes.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_versioning" "notes" {
  bucket = aws_s3_bucket.notes.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "notes" {
  bucket = aws_s3_bucket.notes.id
  rule {
    bucket_key_enabled = true
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "notes" {
  bucket = aws_s3_bucket.notes.id

  # Versioning must be on before lifecycle rules that reference noncurrent versions.
  depends_on = [aws_s3_bucket_versioning.notes]

  rule {
    id     = "expire-old-versions"
    status = "Enabled"
    filter {}

    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_days
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }
  }

  rule {
    id     = "remove-expired-delete-markers"
    status = "Enabled"
    filter {}

    expiration {
      expired_object_delete_marker = true
    }
  }
}

# Deny any request that is not TLS.
data "aws_iam_policy_document" "bucket_tls_only" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.notes.arn, "${aws_s3_bucket.notes.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "notes" {
  bucket = aws_s3_bucket.notes.id
  policy = data.aws_iam_policy_document.bucket_tls_only.json

  depends_on = [aws_s3_bucket_public_access_block.notes]
}

# ------------------------------------------------------------------ IAM role

data "aws_iam_policy_document" "assume_ec2" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name               = "${var.name}-instance"
  assume_role_policy = data.aws_iam_policy_document.assume_ec2.json
}

# Read/write only the notes/ prefix. ListBucket is needed so a missing key is a 404, not a 403.
data "aws_iam_policy_document" "notes_access" {
  statement {
    sid       = "ReadWriteNotesObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.notes.arn}/notes/*"]
  }

  statement {
    sid       = "ListNotesPrefix"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.notes.arn]

    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["notes", "notes/*"]
    }
  }
}

resource "aws_iam_role_policy" "notes_access" {
  name   = "notes-access"
  role   = aws_iam_role.app.id
  policy = data.aws_iam_policy_document.notes_access.json
}

# Session Manager (replaces SSH).
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.name}-instance"
  role = aws_iam_role.app.name
}

# ------------------------------------------------------------------- Network

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
  filter {
    name   = "default-for-az"
    values = ["true"]
  }
}

resource "aws_security_group" "app" {
  name        = "${var.name}-app"
  description = "PrivateBin: app port from one IP, HTTPS out only"
  vpc_id      = data.aws_vpc.default.id
}

resource "aws_vpc_security_group_ingress_rule" "app" {
  security_group_id = aws_security_group.app.id
  description       = "PrivateBin from the operator IP only"
  cidr_ipv4         = var.allowed_cidr
  from_port         = var.app_port
  to_port           = var.app_port
  ip_protocol       = "tcp"
}

# SSM, S3 and the Docker/dnf repositories are all reached over 443.
resource "aws_vpc_security_group_egress_rule" "https" {
  security_group_id = aws_security_group.app.id
  description       = "HTTPS out (SSM, S3, Docker Hub, dnf)"
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

# ------------------------------------------------------------------- Compute

data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "app" {
  #checkov:skip=CKV_AWS_88:A public IP is the requirement; it is locked down by the security group.
  #checkov:skip=CKV_AWS_126:Detailed monitoring is a paid add-on and not needed for a lab.
  #checkov:skip=CKV_AWS_135:t3 instances are EBS-optimized by default.
  ami                         = nonsensitive(data.aws_ssm_parameter.al2023.value)
  instance_type               = var.instance_type
  subnet_id                   = sort(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids      = [aws_security_group.app.id]
  iam_instance_profile        = aws_iam_instance_profile.app.name
  associate_public_ip_address = true
  monitoring                  = false
  ebs_optimized               = true

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    bucket  = aws_s3_bucket.notes.id
    region  = var.region
    port    = var.app_port
    version = var.privatebin_version
  })
  user_data_replace_on_change = true # image upgrade => fresh instance, notes stay in S3

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # IMDSv2 only
    http_put_response_hop_limit = 2          # the container is one hop further than the host
  }

  root_block_device {
    encrypted   = true
    volume_type = "gp3"
    volume_size = 8
    tags        = local.tags
  }

  tags = { Name = var.name }

  lifecycle {
    # A newer AL2023 AMI is published every few weeks; do not replace the box (and show a diff) because of it.
    ignore_changes = [ami]
  }
}
