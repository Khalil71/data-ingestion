
resource "aws_kinesis_firehose_delivery_stream" "orders_delivery_stream" {
  name = "${var.app_prefix}-firehose-delivery-stream"
  depends_on = ["aws_s3_bucket.orders_delivery_s3_bucket"]
  
  destination = "extended_s3"
  
  extended_s3_configuration {
    role_arn           = aws_iam_role.orders_stream_consumer_firehose_role.arn
    bucket_arn         = aws_s3_bucket.orders_delivery_s3_bucket.arn
    buffer_size        = 64
    buffer_interval    = 60
    cloudwatch_logging_options {
      enabled = true
      log_group_name = "/aws/kinesis_firehose_delivery_stream/orders_delivery_stream"
      log_stream_name = "orders_delivery_stream"
    }
    compression_format = "UNCOMPRESSED"
    prefix = "order/data=!{timestamp:yyyy}-!{timestamp:MM}-!{timestamp:dd}/"
    error_output_prefix = "order/error=!{firehose:error-output-type}data=!{timestamp:yyyy}-!{timestamp:MM}-!{timestamp:dd}/"
  

    processing_configuration {
      enabled = "true"

      processors {
        type = "Lambda"

        parameters {
          parameter_name  = "LambdaArn"
          parameter_value = "${aws_lambda_function.lambda_orders_stream_consumer.arn}:$LATEST"
        }
      }
    }
   }
}