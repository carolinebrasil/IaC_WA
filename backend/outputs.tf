output "s3_state_bucket_name" {
  value       = aws_s3_bucket.this.id
  description = "S3 state bucket name for backend TF"
}

output "dynamodb_state_lock_table_name" {
  value       = aws_dynamodb_table.this.id
  description = "DynamoDB state lock table name"

}

output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "caller_user" {
  value = data.aws_caller_identity.current.user_id
}

output "s3_region" {
  value = aws_s3_bucket.this.region

}
