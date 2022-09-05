##Standerd output values

output "private_ip" {
  value = zipmap(aws_instance.studocu-webserver.*.tags.Name, aws_instance.studocu-webserver.*.private_ip)
}

output "elb-ws" {
  value = aws_elb.elb-ws.dns_name
}

output "webserver-url" {
  value = aws_route53_record.studocu-url.fqdn
}
