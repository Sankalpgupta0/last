# Questions

1. **Shared state bucket.** What is its name, and is there a per-person key convention? `backend.hcl.example` uses `privatebin/terraform.tfstate`, which would collide if several people share the bucket.
2. **"No inbound rules" vs "3344 open to your IP".** The brief says both. I built the IP rule so the public-IP demo works. For zero inbound, delete `aws_vpc_security_group_ingress_rule.app`; the Session Manager tunnel still works. Which do you want as the default?
3. **"HTTP" in the bucket and egress lines.** I read these as HTTPS: the bucket denies non-TLS and egress is 443 only. Correct?
4. **Public-IP demo.** PrivateBin needs a secure context, so saving a note over `http://<ip>:3344` is expected to fail (see README). Is the tunnel enough for "prove it", or should HTTPS via ALB + ACM be part of the main scope?
5. **Nightly destroy.** Is a GitHub Actions schedule with an OIDC role acceptable, or do you want a local cron / AWS-side scheduler? The workflow needs `AWS_ROLE_ARN` and `TF_STATE_BUCKET`.
6. **Encryption.** SSE-S3 is used. Is SSE-KMS with a customer key required?
7. **Stretch choice.** Fargate or EC2 in a private subnet: which one do you want built?
