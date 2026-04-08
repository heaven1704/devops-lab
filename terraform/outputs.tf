output "ec2_public_ip" {
  value = aws_instance.lab_instance.public_ip
}

output "s3_bucket_name" {
  value = aws_s3_bucket.lab_bucket.bucket
}

output "lambda_function_name" {
  value = aws_lambda_function.lab_function.function_name
}