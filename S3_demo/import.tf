import {
  to = aws_lambda_function.imported_lambda
  id = "abc_publishGlueJobStatus" # The exact name of your Lambda function in AWS
}

# 2. Define the matching resource block where the infrastructure will be managed
resource "aws_lambda_function" "imported_lambda" {
  function_name = "abc_publishGlueJobStatus"
  role          = "arn:aws:iam::456568168979:role/service-role/abc_publishGlueJobStatus-role-oz2s81mp"
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.14"

  # Note: You can use Terraform's automatic code generation 
  # to automatically populate these configuration attributes.
}
