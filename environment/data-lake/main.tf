module "circulate_data_lake" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket            = "${var.name}-${var.env}-data"
  block_public_acls = true

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning = {
    enabled = true
  }
}

module "analytics_sqs" {
  source  = "terraform-aws-modules/sqs/aws"

  name = "${var.name}-${var.env}-analytics-queue"

  create_queue_policy = true
  queue_policy_statements = {
    sns = {
      sid     = "SNSPublish"
      actions = ["sqs:SendMessage"]

      principals = [
        {
          type        = "Service"
          identifiers = ["sns.amazonaws.com"]
        }
      ]

      condition = {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values   = [module.sns.topic_arn]
      }
    }
  }
  fifo_queue = true
  create_dlq_queue_policy = true
  create_dlq = true
  
  redrive_policy = {
    maxReceiveCount = 5
  }
}

module "sns" {
  source  = "terraform-aws-modules/sns/aws"
  version = ">= 5.0"

  name = "${var.name}-${var.env}-s3-event-topic"

  topic_policy_statements = {
    sqs = {
      sid = "SQSSubscribe"
      actions = [
        "sns:Subscribe",
        "sns:Receive",
      ]

      principals = [{
        type        = "AWS"
        identifiers = ["*"]
      }]

      conditions = [{
        test     = "StringLike"
        variable = "sns:Endpoint"
        values   = [module.analytics_sqs.queue_arn]
      }]
    }
  }

  subscriptions = {
    sqs = {
      protocol = "sqs"
      endpoint = module.analytics_sqs.queue_arn
    }
  }
}

module "circulate_data_lake_notifications" {
  source = "terraform-aws-modules/s3-bucket/aws//modules/notification"

  bucket            = module.circulate_data_lake.s3_bucket_id
  create = true
  sns_notifications = {
    sns1 = {
      id = module.sns.topic_id
      topic_arn = module.sns.topic_arn
      events = ["s3:ObjectCreated"]
      # filter_prefix =
      # filter_suffix = 
    }
  } 
}
