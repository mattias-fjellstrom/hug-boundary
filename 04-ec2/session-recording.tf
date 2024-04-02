data "aws_s3_bucket" "session_recording" {
  bucket = "hug-boundary-session-recording"
}

data "aws_iam_role" "workers" {
  name = "boundary-workers"
}

resource "boundary_storage_bucket" "session_recording" {
  name        = "aws-storage-bucket-session-recordings"
  description = "Storage bucket for session recordings"
  scope_id    = data.boundary_scope.organization.id
  plugin_name = "aws"
  bucket_name = data.aws_s3_bucket.session_recording.bucket

  attributes_json = jsonencode({
    "region"                      = var.aws_region
    "role_arn"                    = data.aws_iam_role.workers.arn
    "disable_credential_rotation" = true
  })

  worker_filter = "\"public\" in \"/tags/subnet\""
}
