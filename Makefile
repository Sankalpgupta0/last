.PHONY: init plan apply destroy tunnel check
init:    ; terraform init -backend-config=backend.hcl
plan:    ; terraform plan
apply:   ; terraform apply
destroy: ; terraform destroy
tunnel:  ; $$(terraform output -raw ssm_port_forward_command)
check:
	terraform fmt -check -recursive
	terraform init -backend=false -input=false >/dev/null
	terraform validate
	tflint --recursive
	checkov -d . --framework terraform --quiet --compact
