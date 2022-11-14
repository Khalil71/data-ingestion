

resource "aws_cloudwatch_log_group" "lambda_orders_log_group" {
  name              = "/aws/lambda/${var.app_prefix}/${aws_lambda_function.lambda_orders.function_name}"
  retention_in_days = 30
  depends_on = ["aws_lambda_function.lambda_orders"]
}

resource "aws_cloudwatch_log_group" "orders_firehose_delivery_stream_log_group" {
  name              = "/aws/kinesis_firehose_delivery_stream/${var.app_prefix}/orders_firehose_delivery_stream"
  retention_in_days = 30
}

resource "aws_cloudwatch_log_stream" "orders_firehose_delivery_stream" {
  name           = "${var.app_prefix}-firehose-delivery-stream"
  log_group_name = "${aws_cloudwatch_log_group.orders_firehose_delivery_stream_log_group.name}"
}
