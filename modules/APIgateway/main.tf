
resource "aws_apigatewayv2_api" "orders_api" {
  name = "${var.app_prefix}-api"
  protocol_type = "HTTP"
  description = "orders api"
  
}

resource "aws_cloudwatch_log_group" "orders-api-log-group" {
  name = "/aws/apigateway/${var.app_prefix}-API-Gateway-Execution-Logs/${var.stage_name}"
  retention_in_days = 30
}

resource "aws_apigatewayv2_model" "orders_model" {
  api_id = aws_apigatewayv2_api.orders_api.id
  name = "${var.app_prefix}model"
  description = "${var.app_prefix}-JSON schema"
  content_type = "application/json"

  schema = <<EOF
  {
      "$schema": "http://json-schema.org/draft-04/schema#",
      "title": "${var.app_prefix}",
      "type": "object",
      "additionalProperties": false,
      "properties": {
        "advertiserId": {
          "type": "string"
        },
        "totalamount": {
          "type": "number"
        },
        "currencyCode": {
          "type": "string"
        },
        "orderReference": {
          "type": "string"
        }
        
      },
      "required": ["advertiserId", "totalamount", "currencyCode", "orderReference"]
  }
  EOF
}

resource "aws_apigatewayv2_integration" "integration" {
  api_id           = aws_apigatewayv2_api.orders_api.id
  integration_type = "AWS_PROXY"

  connection_type = "INTERNET"
  description = "Lambda handler"
  integration_method = "POST"
  integration_uri = aws_lambda_function.lambda_orders.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}


resource "aws_apigatewayv2_integration_response" "orders_integration_response" {
  api_id = aws_apigatewayv2_api.orders_api.id
  integration_id = aws_apigatewayv2_integration.integration.id
  integration_response_key = "/200/"
   
  depends_on = ["aws_apigatewayv2_api.orders_api",
                 "aws_apigatewayv2_integration.integration"]
}

resource "aws_apigatewayv2_deployment" "orders_deployment" {
  
  api_id = aws_apigatewayv2_api.orders_api.id
  description = "Example deployment"

  depends_on = ["aws_api_gateway_integration.integration"]
}

resource "aws_acm_certificate" "orders" {
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_apigatewayv2_domain_name" "regional" {
  # var.regional_hostname = api-eu.example.com for eu-central-1
  domain_name = "${replace(var.regional_hostname, "/[.]$/", "")}"

  domain_name_configuration {
    certificate_arn = aws_acm_certificate.orders.arn
    endpoint_type = "REGIONAL"
    security_policy = "TLS_1_2"
  }
}

resource "aws_apigatewayv2_api_mapping" "orders" {
  api_id = aws_apigatewayv2_api.orders_api.id
  domain_name = aws_apigatewayv2_domain_name.regional.id
  stage = aws_apigatewayv2_stage.orders.id
}

resource "aws_apigatewayv2_stage" "orders" {
  api_id = aws_apigatewayv2_api.orders_api.id
  name = var.stage_name
}

resource "aws_route53_record" "regional" {
  zone_id = "${data.aws_route53_zone.public_zone.id}"

  name = "${var.regional_hostname}"  # e.g. api-eu.example.com
  type = "A"

  alias {
    name = "${aws_apigatewayv2_domain_name.regional.regional_domain_name}"
    zone_id = "${aws_apigatewayv2_domain_name.regional.regional_zone_id}"
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "balanced" {
    count = "${length(var.deploy_hostnames)}"
    zone_id = "${data.aws_route53_zone.public_zone.id}"
    name = "${var.global_hostname}"  # e.g. api.example.com
    type = "CNAME"
    ttl = "60"
    set_identifier = "${element(var.deploy_hostnames, count.index)}"
    health_check_id = "${element(aws_route53_health_check.health.*.id, count.index)}"

    records = [
        "${element(var.deploy_hostnames, count.index)}"
    ]
    weighted_routing_policy  {
        weight = 1
    }
}

resource "aws_route53_health_check" "health" {
  count             = "${var.aws_region == "eu-central-1" ? length(var.deploy_hostnames) : 0}" # Only deploy it once
  fqdn              = "${element(var.deploy_hostnames, count.index)}"
  type              = "HTTPS"
  port              = "443"
  resource_path     = "/"  # Make a request to https://api-*.example.com/
  failure_threshold = "5"
  request_interval  = "30"
}

resource "aws_api_gateway_domain_name" "global" {
  domain_name = "${replace(var.global_hostname, "/[.]$/", "")}"

  regional_certificate_arn = "${var.regional_certificate_arn}"
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_base_path_mapping" "global" {
  api_id      = "${aws_apigatewayv2_api.orders_api.id}"
  stage_name  = "${aws_apigatewayv2_deployment.orders_deployment.stage_name}"
  domain_name = "${aws_apigatewayv2_domain_name.global.domain_name}"
}