/**
 * S3 Vectors store: a vector bucket + one index.
 *
 * The direct-access vector store — the caller embeds and put/query-vectors itself,
 * replacing a Bedrock Knowledge Base. Encryption is S3-managed (AES256) unless a
 * kms_key_arn is supplied. Both resources carry prevent_destroy: the index holds
 * embeddings that are slow and expensive to rebuild.
 */

resource "aws_s3vectors_vector_bucket" "this" {
  vector_bucket_name = var.vector_bucket_name
  tags               = var.tags

  encryption_configuration = var.kms_key_arn == null ? null : [{
    sse_type    = "aws:kms"
    kms_key_arn = var.kms_key_arn
  }]

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3vectors_index" "this" {
  vector_bucket_name = aws_s3vectors_vector_bucket.this.vector_bucket_name
  index_name         = var.index_name
  data_type          = var.data_type
  dimension          = var.dimension
  distance_metric    = var.distance_metric
  tags               = var.tags

  metadata_configuration {
    non_filterable_metadata_keys = var.non_filterable_metadata_keys
  }

  lifecycle {
    prevent_destroy = true
  }
}
