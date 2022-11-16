
data "aws_iam_policy_document" "AWSLambdaTrustPolicy" {
  statement {
    actions    = ["sts:AssumeRole"]
    effect     = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "orders_lambda_role" {
  name = "${var.app_prefix}-lambda-role"
  assume_role_policy = "${data.aws_iam_policy_document.AWSLambdaTrustPolicy.json}"
}

resource "aws_lambda_permission" "apigw_lambda" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.lambda_orders.arn}"
  principal     = "apigateway.amazonaws.com"

  # The /*/*/* part allows invocation from any stage, method and resource path
  # within API Gateway REST API.
  source_arn = "${aws_apigatewayv2_api.orders_api.execution_arn}/*/*/*"
  depends_on = ["aws_lambda_function.lambda_orders","aws_apigatewayv2_api.orders_api"]
}

resource "aws_iam_role_policy_attachment" "orderslambda_policy" {
  role       = aws_iam_role.orders_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role" "orders_stream_consumer_firehose_role" {
  name = "${var.app_prefix}-stream-consumer-firehose-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "firehose.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
POLICY
}


resource "aws_iam_role_policy" "orders_stream_consumer_firehose_inline_policy" {
  name   = "${var.app_prefix}-stream-consumer-firehose-inline_policy"
  role   = aws_iam_role.orders_stream_consumer_firehose_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:*",
        "lambda:*",
        "s3:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "orders_invocation_role" {
  name = "${var.app_prefix}-api-gateway-auth-invocation"
  path = "/"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}


resource "aws_iam_role" "orders_api_gateway_cloudwatch_role" {
  name = "${var.app_prefix}-api-gateway-cloudwatch-global-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "apigateway.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}
