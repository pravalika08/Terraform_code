output "prod_vpc" {
  value = aws_vpc.prod_vpc.id
}
output "id" {
    value = aws_security_group.sg_1.id
    }