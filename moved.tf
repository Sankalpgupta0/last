# Refactor: the flat resources now live in module.privatebin. These blocks make Terraform
# rename the state entries instead of destroy/create, so `terraform plan` shows 0 changes.
# Safe to delete once every state that used the flat layout has been applied.

moved {
  from = aws_s3_bucket.notes
  to   = module.privatebin.aws_s3_bucket.notes
}

moved {
  from = aws_s3_bucket_public_access_block.notes
  to   = module.privatebin.aws_s3_bucket_public_access_block.notes
}

moved {
  from = aws_s3_bucket_ownership_controls.notes
  to   = module.privatebin.aws_s3_bucket_ownership_controls.notes
}

moved {
  from = aws_s3_bucket_versioning.notes
  to   = module.privatebin.aws_s3_bucket_versioning.notes
}

moved {
  from = aws_s3_bucket_server_side_encryption_configuration.notes
  to   = module.privatebin.aws_s3_bucket_server_side_encryption_configuration.notes
}

moved {
  from = aws_s3_bucket_lifecycle_configuration.notes
  to   = module.privatebin.aws_s3_bucket_lifecycle_configuration.notes
}

moved {
  from = aws_s3_bucket_policy.notes
  to   = module.privatebin.aws_s3_bucket_policy.notes
}

moved {
  from = aws_iam_role.app
  to   = module.privatebin.aws_iam_role.app
}

moved {
  from = aws_iam_role_policy.notes_access
  to   = module.privatebin.aws_iam_role_policy.notes_access
}

moved {
  from = aws_iam_role_policy_attachment.ssm
  to   = module.privatebin.aws_iam_role_policy_attachment.ssm
}

moved {
  from = aws_iam_instance_profile.app
  to   = module.privatebin.aws_iam_instance_profile.app
}

moved {
  from = aws_security_group.app
  to   = module.privatebin.aws_security_group.app
}

moved {
  from = aws_vpc_security_group_ingress_rule.app
  to   = module.privatebin.aws_vpc_security_group_ingress_rule.app
}

moved {
  from = aws_vpc_security_group_egress_rule.https
  to   = module.privatebin.aws_vpc_security_group_egress_rule.https
}

moved {
  from = aws_instance.app
  to   = module.privatebin.aws_instance.app
}
