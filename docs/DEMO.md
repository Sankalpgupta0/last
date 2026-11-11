# 10-minute demo script

| Min | Do | Say / show |
|---|---|---|
| 0-1 | `docker run --rm -p 3344:8080 privatebin/nginx-fpm-alpine:2.0.6`, make a note, burn-after-reading, Ctrl+C | `--rm` deletes the notes. That is why AWS uses S3. |
| 1-3 | Walk `modules/privatebin/`: `main.tf` sections | S3 hardening, IAM scoped to `notes/`, SG, IMDSv2, AMI lookup |
| 3-4 | `make init && make plan` | state in the shared bucket, lock file `.tflock` appears during plan |
| 4-6 | `make apply` while talking about `user_data` | no keys; hop limit 2; `--cap-drop ALL` |
| 6-8 | `make tunnel`, open http://localhost:3344, save a note; `aws s3 ls s3://<bucket>/notes/ --recursive` | the encrypted note object is in S3 |
| 8-9 | `aws ssm start-session` shell: `docker ps`, `curl -s -H "X-aws-ec2-metadata-token: x" 169.254.169.254` is refused without a token | no SSH, IMDSv2 enforced |
| 9-10 | Change `privatebin_version`, `make plan` (1 replace), then `make destroy` | upgrade replaces the box, notes stay; destroy empties the bucket |

Also show: CI run (fmt, validate, tflint, checkov green) and `terraform plan` = "No changes" after the module refactor.
