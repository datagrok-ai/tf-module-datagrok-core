output "lb_dns_name" {
  description = "Load balancer DNS name"
  value       = lookup(aws_cloudformation_stack.datagrok.outputs, "DatagrokLoadBalancerDNSName", "")
}

output "admin_password" {
  description = "Admin password for first login"
  value       = lookup(aws_cloudformation_stack.datagrok.outputs, "DatagrokAdminPassword", "")
}
