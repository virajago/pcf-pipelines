# PCF on GCP

![Concourse Pipeline](embed.png)

This pipeline uses Terraform to create all the infrastructure required to run a
3 AZ PCF deployment on GCP per the Customer[0] [reference
architecture](http://docs.pivotal.io/pivotalcf/1-10/refarch/gcp/gcp_ref_arch.html).

## Usage

This pipeline downloads artifacts from DockerHub (czero/cflinuxfs2 and custom
docker-image resources) and the configured S3-compatible object store
(Terraform .tfstate file), and as such the Concourse instance must have access
to those. Note that Terraform outputs a .tfstate file that contains plaintext
secrets, so it is advised you use a private S3-compatible store rather than AWS
S3.

1. Within Google Cloud Platform, enable the following:
  * GCP Compute API [here](https://console.cloud.google.com/apis/api/compute_component)
  * GCP Storage API [here](https://console.cloud.google.com/apis/api/storage_component)
  * GCP SQL API [here](https://console.cloud.google.com/apis/api/sql_component)
  * GCP DNS API [here](https://console.cloud.google.com/apis/api/dns)
  * GCP Cloud Resource Manager API [here](https://console.cloud.google.com/apis/api/cloudresourcemanager.googleapis.com/overview)

2. Create a new service account key in Google Cloud Platform that has the following IAM roles:
  * Cloud SQL Admin
  * Compute Instance Admin (v1)
  * Compute Network Admin
  * Compute Security Admin
  * DNS Administrator
  * Storage Admin

3. [Set the pipeline](http://concourse.ci/single-page.html#fly-set-pipeline), using your updated params.yml:
  ```
  fly -t lite set-pipeline -p deploy-pcf -c pipeline.yml -l params.yml
  ```

4. Unpause the pipeline
5. Run `bootstrap-terraform-state` to bootstrap the Terraform .tfstate file. This only needs to be run once.
6. `upload-opsman-image` will automatically upload the latest matching version of Operations Manager
7. Run the `create-initial-terraform-state` job manually. This will prepare the s3 resource that holds the terraform state.
8. Trigger the `create-infrastructure` job. `create-infrastructure` will output at the end the DNS settings that you must configure before continuing.
9. Once DNS is set up you can run `configure-director`. From there the pipeline should automatically run through to the end.

### Tearing down the environment

There is a job, `wipe-env`, which you can run to destroy the infrastructure
that was created by `create-infrastructure`.

_**Note: This job currently is not all-encompassing. If you have deployed ERT you will want to delete ERT from within Ops Manager before proceeding with `wipe-env`, as well as deleting the BOSH director VM from within GCP. This will be done automatically in the future.**_

If you want to bring the environment up again, run `create-infrastructure`.

## Known Issues

### `wipe-env` job
* The job does not account for installed tiles, which means VMs created by tile
  installations will be left behind and/or prevent wipe-env from completing.
  Delete the tiles manually prior to running `wipe-env` as a workaround.
* The job does not account for the BOSH director VM, which will prevent the job
  from completing. Delete the director VM manually in the GCP console as a
  workaround.

### Missing Jumpbox
* There is presently no jumpbox installed as part of the Terraform scripts. If
  you need to SSH onto the Ops Manager VM you'll need to add an SSH key from
  within GCP to the instance, and also add the `allow-ssh` tag to the network
  access tags.

### Cloud SQL Authorized Networks

There is a set of authorized networks added for the Cloud SQL instance which
has been modified to include 0.0.0.0/0. This is due to Cloud SQL only
managing access through public networks. We don't have a good way to keep
updated with Google Compute Engine CIDRs, and the Google Cloud Proxy is not
yet available on BOSH-deployed VMs. Thus, to allow Elastic Runtime access to
Cloud SQL, we allow 0.0.0.0/0. When a better solution comes around we'll be
able to remove it and allow only the other authorized networks that are
configured.

There is a (private, sorry) [Pivotal Tracker
story](https://www.pivotaltracker.com/n/projects/975916/stories/133642819) to
address this issue.
