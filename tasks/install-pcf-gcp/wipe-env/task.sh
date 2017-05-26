#!/bin/bash
set -e

root=$PWD

export GOOGLE_CREDENTIALS=${GCP_SERVICE_ACCOUNT_KEY}
export GOOGLE_PROJECT=${GCP_PROJECT_ID}
export GOOGLE_REGION=${GCP_REGION}

echo "Deleting PCF installation..."
om-linux \
  --target https://$OPSMAN_URI \
  --skip-ssl-validation \
  --username $OPSMAN_USERNAME \
  --password $OPSMAN_PASSWORD \
  delete-installation

echo "Deleting provisioned infrastructure..."
terraform destroy -force \
  -state $root/terraform-state/*.tfstate \
  -var "gcp_proj_id=dontcare" \
  -var "gcp_region=dontcare" \
  -var "gcp_zone_1=dontcare" \
  -var "gcp_zone_2=dontcare" \
  -var "gcp_zone_3=dontcare" \
  -var "prefix=dontcare" \
  -var "pcf_opsman_image_name=dontcare" \
  -var "pcf_ert_domain=dontcare" \
  -var "pcf_ert_ssl_cert=dontcare" \
  -var "pcf_ert_ssl_key=dontcare" \
  -var "ert_sql_instance_name=dontcare" \
  -var "ert_sql_db_username=dontcare" \
  -var "ert_sql_db_password=dontcare" \
  -state-out $root/wipe-output/terraform.tfstate \
  pcf-pipelines/tasks/install-pcf-gcp/terraform
