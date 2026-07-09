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
# Note: R2 has no DynamoDB, so there is no lock table. OpenTofu 1.11 supports
# S3-native locking via `use_lockfile = true` (conditional writes) — worth
# enabling once verified against R2, to prevent concurrent CI/local applies.
terraform {
  backend "s3" {
    bucket = "blackstar-observability-tfstate-prod"
    key    = "envs/prod/terraform.tfstate"
    region = "auto"

    use_path_style              = true
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}
