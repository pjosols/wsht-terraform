/**
 * Provision a Bedrock Knowledge Base backed by S3 Vectors for RAG and semantic search.
 *
 * Creates a vector bucket, vector index, KB IAM role, Bedrock Knowledge Base, and a
 * CUSTOM data source for direct ingestion via IngestKnowledgeBaseDocuments. The caller
 * is responsible for granting their compute (e.g. Lambda) permission to call
 * bedrock:IngestKnowledgeBaseDocuments using the knowledge_base_arn output.
 */

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.region
}

# --- s3 vectors ---

resource "aws_s3vectors_vector_bucket" "this" {
  vector_bucket_name = var.name
  tags               = var.tags
}

resource "aws_s3vectors_index" "this" {
  vector_bucket_name = aws_s3vectors_vector_bucket.this.vector_bucket_name
  index_name         = var.name
  data_type          = "float32"
  dimension          = var.vector_dimension
  distance_metric    = "cosine"

  metadata_configuration {
    # AMAZON_BEDROCK_TEXT and AMAZON_BEDROCK_METADATA are required by Bedrock KB
    non_filterable_metadata_keys = distinct(concat(
      ["AMAZON_BEDROCK_TEXT", "AMAZON_BEDROCK_METADATA"],
      var.non_filterable_metadata_keys
    ))
  }
}

# --- iam ---

resource "aws_iam_role" "this" {
  name = "${var.name}-kb"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "bedrock.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = { "aws:SourceAccount" = local.account_id }
        ArnLike      = { "aws:SourceArn" = "arn:aws:bedrock:${local.region}:${local.account_id}:knowledge-base/*" }
      }
    }]
  })
}

resource "aws_iam_role_policy" "embedding" {
  name = "embedding"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["bedrock:InvokeModel"]
      Resource = var.embedding_model_arn
    }]
  })
}

resource "aws_iam_role_policy" "vectors" {
  name = "s3-vectors"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3vectors:*"]
      Resource = aws_s3vectors_index.this.index_arn
    }]
  })
}

# --- knowledge base ---

resource "aws_bedrockagent_knowledge_base" "this" {
  name     = var.name
  role_arn = aws_iam_role.this.arn
  tags     = var.tags

  knowledge_base_configuration {
    type = "VECTOR"
    vector_knowledge_base_configuration {
      embedding_model_arn = var.embedding_model_arn
    }
  }

  storage_configuration {
    type = "S3_VECTORS"
    s3_vectors_configuration {
      index_arn = aws_s3vectors_index.this.index_arn
    }
  }
}

resource "aws_bedrockagent_data_source" "this" {
  knowledge_base_id = aws_bedrockagent_knowledge_base.this.id
  name              = "${var.name}-direct-ingest"

  data_source_configuration {
    type = "CUSTOM"
  }

  vector_ingestion_configuration {
    # FIXED_SIZE so large emails are split into multiple embeddings instead of
    # one — a single un-chunked marketing email exceeded Titan v2's ~8k-token
    # limit and silently failed to index. 300 tokens / 20% overlap keeps each
    # chunk well under the limit while preserving context across boundaries.
    chunking_configuration {
      chunking_strategy = "FIXED_SIZE"
      fixed_size_chunking_configuration {
        max_tokens         = 300
        overlap_percentage = 20
      }
    }
  }
}
