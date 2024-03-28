# Request an ACM certificate for the domain
resource "aws_acm_certificate" "prathap_shop_cert" {
  domain_name       = "abc.prathap.shop"
  validation_method = "DNS"
}

# Create a Route53 hosted zone for the domain
resource "aws_route53_zone" "prathap_shop_zone" {
  name = "prathap.shop"
}

# Validate the ACM certificate using DNS records
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.prathap_shop_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.prathap_shop_zone.zone_id
}

# Wait for the certificate to be validated
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.prathap_shop_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Store the ACM certificate ARN in the Systems Manager Parameter Store
resource "aws_ssm_parameter" "cert_arn_parameter" {
  name  = "/prathap/shop/cert_arn"
  type  = "String"
  value = aws_acm_certificate_validation.cert_validation.certificate_arn
}

# Output the hosted zone ID and name server records
output "hosted_zone_id" {
  description = "Route53 Hosted Zone ID"
  value       = aws_route53_zone.prathap_shop_zone.zone_id
}

output "name_servers" {
  description = "Name servers for the hosted zone"
  value       = aws_route53_zone.prathap_shop_zone.name_servers
}