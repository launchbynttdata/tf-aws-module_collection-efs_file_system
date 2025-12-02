output "account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "arn" {
  value = data.aws_caller_identity.current.arn
}

output "hello_message" {
  value = local.hello_message
}
