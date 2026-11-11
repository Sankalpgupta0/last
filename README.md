# PrivateBin on AWS (Terraform)

PrivateBin `privatebin/s3` in Docker on one `t3.micro` (Amazon Linux 2023, eu-north-1).
Notes are stored in a private, encrypted, versioned S3 bucket. The instance reaches it through an IAM role, so there are no access keys anywhere.

```
 you ──(3344, your IP only)──▶ EC2 t3.micro ──(IAM role, HTTPS)──▶ S3  notes/
  └──(Session Manager tunnel / shell, no SSH)──┘            private · SSE-S3 · versioned
```

## What gets built

| Piece | Choice |
|---|---|
| S3 | public access blocked, `BucketOwnerEnforced`, SSE-S3, versioning, noncurrent versions expire after 30 days, bucket policy denies non-TLS |
| IAM | instance role: Get/Put/Delete on `notes/*`, `ListBucket` limited to the `notes` prefix, plus `AmazonSSMManagedInstanceCore` |
| Network | default VPC; SG ingress is 3344 from `allowed_cidr` only (`0.0.0.0/0` is rejected); egress is 443 only (SSM, S3, Docker Hub, dnf) |
| EC2 | AMI looked up from the SSM public parameter, IMDSv2 required (hop limit 2 so the container can reach it), encrypted gp3 root, no key pair, `user_data` installs Docker and runs the image |
| Tags | `default_tags` on the provider (Project, Owner, Environment, ManagedBy, Teardown) plus `Name`; root volume tagged explicitly |
| State | S3 backend in the shared bucket, native locking (`use_lockfile`, Terraform >= 1.10), no DynamoDB |

## Use it

```sh
cp backend.hcl.example backend.hcl            # put the shared bucket name in
cp terraform.tfvars.example terraform.tfvars  # your IP: curl -s https://checkip.amazonaws.com
make init && make apply
make tunnel                                   # needs the Session Manager plugin; then open http://localhost:3344
make destroy                                  # or let .github/workflows/destroy-nightly.yml do it at 18:00 UTC
```

Outputs: `bucket_name`, `instance_id`, `public_ip`, `ssm_port_forward_command`, `ssm_shell_command`.

## Layout and the refactor

`modules/privatebin/` holds every resource. The root only sets the provider, tags and the module call.
`moved.tf` maps each old flat address to `module.privatebin.*`, so a state created by the first commit (`f01d22b`) plans as 0 changes after the refactor. Delete `moved.tf` once nobody has the old layout.

## CI (`.github/workflows/ci.yml`)

`terraform fmt -check`, `init -backend=false`, `validate`, `tflint` (AWS ruleset 0.50.0), `checkov`.
Locally on the current code: fmt, validate and tflint are clean; checkov reports 75 passed, 0 failed, 7 skipped. Each skip is an inline `#checkov:skip` with a reason (no access logging, no replication, SSE-S3 instead of KMS, public IP by design, and so on).

## Image upgrade

`privatebin_version` is a variable. 2.0.6 → 2.1.1 changes `user_data`, and `user_data_replace_on_change` replaces the instance. Notes survive because they live in S3. I checked both versions start and read the mounted config with the same hardening flags.

## Known limits

- **Plain HTTP and the public IP.** PrivateBin encrypts in the browser with WebCrypto, which browsers only enable on HTTPS or `localhost`. Over `http://<public-ip>:3344` the page loads but saving a note is expected to fail. Over the Session Manager tunnel (`http://localhost:3344`) it works. Real HTTPS needs an ALB with ACM, which is the stretch goal.
- **AMI drift.** `ignore_changes = [ami]` keeps a new AL2023 release from replacing the box and breaking the 0-change plan. To pick up a new AMI, taint the instance.
- **Bucket deletion.** `force_destroy = true` so the nightly destroy can empty a versioned bucket. All notes are lost every evening, by design.

## Stretch (not built)

Fargate task in a private subnet behind an ALB with an ACM certificate (HTTPS), S3 reached through a gateway endpoint, task role instead of instance role, same bucket module. This removes the public IP, the SG ingress for one IP and the WebCrypto problem. It is a design only.
