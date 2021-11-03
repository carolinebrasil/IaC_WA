output "s3_state_bucket_name" {
  value       = aws_s3_bucket.this.id
  description = "S3 state bucket name for backend TF"
}

output "dynamodb_state_lock_table_name" {
  value       = aws_dynamodb_table.this.id
  description = "DynamoDB state lock table name"

}