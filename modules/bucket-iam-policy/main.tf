locals {
  # If neither `read_only_paths` nor `read_write_paths` are provided, default to
  # read-only access to the entire bucket
  ro_paths     = length(var.read_only_paths) + length(var.read_write_paths) == 0 ? [""] : var.read_only_paths
  ro_paths_map = { for idx, val in local.ro_paths : idx => val }
  rw_paths_map = { for idx, val in var.read_write_paths : idx => val }
}

# Policy document for read-only access to entire bucket (bucket, bucket/*)
data "aws_iam_policy_document" "ro_source_policy_doc" {
  count = length(local.ro_paths) == 0 ? 0 : 1

  version = "2012-10-17"

  statement {
    sid     = "ReadOnlyPolicy0"
    effect  = "Allow"
    actions = var.read_only_actions
    resources = [
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
  }
}

# If any read_only_paths are specified, the read-only source policy doc will be
# overwritten by a scoped down bucket resource (bucket/some/path,
# bucket/some/path/*)
data "aws_iam_policy_document" "path_specific_ro_doc" {
  count = length(local.ro_paths) == 0 ? 0 : 1

  version     = "2012-10-17"
  source_json = data.aws_iam_policy_document.ro_source_policy_doc[0].json

  dynamic "statement" {
    for_each = local.ro_paths_map

    content {
      sid     = "ReadOnlyPolicy${statement.key}"
      effect  = "Allow"
      actions = var.read_only_actions
      resources = [
        "arn:aws:s3:::${var.bucket_name}/${statement.value}",
        "arn:aws:s3:::${var.bucket_name}/${statement.value}/*"
      ]
    }
  }
}

# Read-only IAM policy
resource "aws_iam_policy" "ro_policy" {
  count = length(local.ro_paths) == 0 ? 0 : 1

  name = "${var.bucket_name}-read-only"
  # If you want read-only access to the entire bucket, path_specific_ro_doc should not overwrite ReadOnlyPolicy0 in ro_source_policy_doc
  policy = local.ro_paths[0] == "" ? data.aws_iam_policy_document.ro_source_policy_doc[0].json : data.aws_iam_policy_document.path_specific_ro_doc[0].json
}

# Policy document for read-write access to entire bucket (bucket, bucket/*)
data "aws_iam_policy_document" "rw_source_policy_doc" {
  count = length(var.read_write_paths) == 0 ? 0 : 1

  version = "2012-10-17"

  statement {
    sid     = "ReadWritePolicy0"
    effect  = "Allow"
    actions = var.read_write_actions
    resources = [
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
  }
}

# If any read_write_paths are specified, the read-write source policy doc will be
# overwritten by a scoped down bucket resource (bucket/some/path,
# bucket/some/path/*)
data "aws_iam_policy_document" "path_specific_rw_doc" {
  count = length(var.read_write_paths) == 0 ? 0 : 1

  version     = "2012-10-17"
  source_json = data.aws_iam_policy_document.rw_source_policy_doc[0].json

  dynamic "statement" {
    for_each = local.rw_paths_map

    content {
      sid     = "ReadWritePolicy${statement.key}"
      effect  = "Allow"
      actions = var.read_write_actions
      resources = [
        "arn:aws:s3:::${var.bucket_name}/${statement.value}",
        "arn:aws:s3:::${var.bucket_name}/${statement.value}/*"
      ]
    }
  }
}

# Read-write IAM policy
resource "aws_iam_policy" "rw_policy" {
  count = length(var.read_write_paths) == 0 ? 0 : 1

  name = "${var.bucket_name}-read-write"
  # If you want read-write access to the entire bucket, path_specific_rw_doc should not overwrite ReadWritePolicy0 in rw_source_policy_doc
  policy = var.read_write_paths[0] == "" ? data.aws_iam_policy_document.rw_source_policy_doc[0].json : data.aws_iam_policy_document.path_specific_rw_doc[0].json
}