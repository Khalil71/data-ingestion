
resource "aws_lambda_function" "lambda_orders" {
  filename      = var.lambda_source_zip_path
  function_name = "${var.app_prefix}-lambda"
  role          = aws_iam_role.orders_lambda_role.arn
  runtime       = "java8"
  memory_size   = 2048
  timeout       = 300
  
  depends_on = ["aws_iam_role.orders_lambda_role", "aws_kinesis_firehose_delivery_stream.orders_firehose_delivery_stream"]

  environment {
    variables = {
      STREAM_NAME = aws_kinesis_firehose_delivery_stream.orders_firehose_delivery_stream.name
      REGION = data.aws_region.current.name
    }
  }
}

resource "aws_lambda_function" "lambda_orders_stream_consumer" {
  filename      = "${var.lambda_source_zip_path}"
  function_name = "${var.app_prefix}-lambda-stream-consumer"
  role          = aws_iam_role.orders_lambda_role.arn
  runtime       = "nodejs"
  memory_size   = 2048
  timeout       = 300
  
  source_code_hash = "${filebase64sha256(var.lambda_source_zip_path)}"
  depends_on = ["aws_iam_role.orders_lambda_role"]

}



output "lambda-orders" {
  value = "${aws_lambda_function.lambda_orders}"
}

