# OpenTofu state for this environment lives in Cloudflare R2 (S3-compatible),
# in the noah@noahwhite.net Cloudflare account. Previously this was local state
# on an operator's machine, which drifted and caused a duplicate-dashboard
# incident (NWSOC-22/NWSOC-23).
#
# A backend block cannot interpolate variables, and this repository is PUBLIC,
# so the Cloudflare account id (which forms the R2 endpoint) is NOT committed.
# The endpoint and credentials are supplied via environment variables:
#
#   AWS_ENDPOINT_URL_S3   https://<cloudflare_account_id>.r2.cloudflarestorage.com
#   AWS_ACCESS_KEY_ID     R2 access key id
#   AWS_SECRET_ACCESS_KEY R2 secret access key
#
# In CI these come from Bitwarden via bitwarden/sm-action (see
# .github/workflows/apply.yml). Locally, export them before running tofu.
#
# One-time migration from the existing local state:
#   export AWS_ENDPOINT_URL_S3="https://<account_id>.r2.cloudflarestorage.com"
#   export AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=...
#   tofu -chdir=opentofu/envs/prod init -migrate-state
#
# State locking uses S3-native locking (`use_lockfile`), not DynamoDB — R2 has
# no DynamoDB. OpenTofu writes a `<key>.tflock` object with `If-None-Match: *`,
# so a second writer gets 412 Precondition Failed and fails to acquire the lock.
# R2's S3 API supports these conditional headers (incl. the `*` wildcard), so
# this works. Needed now that CI (.github/workflows/apply.yml) and local applies
# can race. The R2 token needs Get/Put/DeleteObject on the lock key.
terraform {
  backend "s3" {
    bucket = "blackstar-observability-tfstate-prod"
    key    = "envs/prod/terraform.tfstate"
    region = "auto"

    use_lockfile                = true
    use_path_style              = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}
