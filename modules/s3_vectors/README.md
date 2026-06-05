# s3_vectors

An S3 Vectors store: one vector bucket + one index. The direct-access vector store the
caller embeds into and queries itself (replacing a Bedrock Knowledge Base).

Both resources carry `prevent_destroy` — the index holds embeddings that are slow and
costly to rebuild. `data_type`, `dimension`, and `distance_metric` are immutable; changing
them forces a recreate.

## Usage

```hcl
module "vectors" {
  source = "git::ssh://git@github.com/pjosols/wsht-terraform.git//modules/s3_vectors?ref=v1.3.0"

  vector_bucket_name           = "wsht-me-email"
  index_name                   = "paul"
  dimension                    = 1024
  distance_metric              = "cosine"
  non_filterable_metadata_keys = ["text", "message_id", "subject"]
  tags                         = { project = "wsht-mail" }
}
```

Pass `kms_key_arn` to encrypt the bucket with a customer-managed key (default: S3-managed
AES256).

## Outputs

`vector_bucket_name`, `vector_bucket_arn`, `index_name`, `index_arn`.
