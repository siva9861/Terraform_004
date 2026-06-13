# Core Lambda Function Block
resource "aws_lambda_function" "example" {
  #filename         = data.archive_file.lambda_zip.output_path
  function_name    = "abc_publishGlueJobStatus"
  role             = "arn:aws:iam::456568168979:role/service-role/abc_publishGlueJobStatus-role-oz2s81mp"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.14"
  #source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}