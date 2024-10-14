resource "aws_mq_configuration" "hpc_1_rabbit" {
  description    = "Rabbit Configuration"
  name           = "hpc-1-rabbit"
  engine_type    = "RabbitMQ"
  engine_version = "3.11.20"

  data = <<DATA
# Default RabbitMQ delivery acknowledgement timeout is 30 minutes in milliseconds
consumer_timeout = 1800000
DATA 
}

resource "aws_mq_broker" "hpc_1_broker" {
  broker_name = "hpc-1-broker"

  configuration {
    id       = aws_mq_configuration.hpc_1_rabbit.id
    revision = aws_mq_configuration.hpc_1_rabbit.latest_revision
  }

  engine_type        = "RabbitMQ"
  engine_version     = "3.11.20"
  host_instance_type = "mq.t3.micro"
  subnet_ids         = [aws_subnet.hpc_1_queue_a.id]
  security_groups    = [aws_security_group.hpc_1_sg.id]

  user {
    username = "hpc-1-admin"
    password = "helpme-understand"
  }
}



module "sqs" {
  source  = "terraform-aws-modules/sqs/aws"
  version = "4.2.1"

  name              = local.sqs_name
  kms_master_key_id = module.kms_hpc_key1.key_arn
  tags = {
    Terraform   = "true"
    Environment = "dev"
  }

}
