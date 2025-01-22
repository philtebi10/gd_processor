# iam.tf

# ------------------------------------------------------------------------
# Data Source: aws_iam_policy_document.ecs_task_trust
# ------------------------------------------------------------------------
# This data source defines the trust relationship policy that allows ECS tasks
# to assume the IAM role. It specifies that the service "ecs-tasks.amazonaws.com"
# is allowed to perform the "sts:AssumeRole" action.
# ------------------------------------------------------------------------
data "aws_iam_policy_document" "ecs_task_trust" {
  statement {
    actions = ["sts:AssumeRole"]  # Allow the action sts:AssumeRole

    principals {
      type        = "Service"                      # Specify the type of principal as Service
      identifiers = ["ecs-tasks.amazonaws.com"]    # The service allowed to assume the role
    }
  }
}

# ------------------------------------------------------------------------
# Resource: aws_iam_role.ecs_task_execution_role
# ------------------------------------------------------------------------
# This IAM role is created for ECS task execution. It uses the trust policy
# defined in the ecs_task_trust data source to allow ECS tasks to assume this role.
# ------------------------------------------------------------------------
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "${var.project_name}-ecs-task-execution-role"  # Name of the IAM role, incorporating the project name variable
  assume_role_policy = data.aws_iam_policy_document.ecs_task_trust.json  # Attach the trust policy JSON to the role
}

# ------------------------------------------------------------------------
# Resource: aws_iam_role_policy_attachment.ecs_task_execution_attach
# ------------------------------------------------------------------------
# This resource attaches the AmazonECSTaskExecutionRolePolicy managed policy to
# the ecs_task_execution_role. This policy grants the necessary permissions for
# ECS tasks to interact with other AWS services.
# ------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name  # The name of the IAM role to attach the policy to
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"  # ARN of the managed policy to attach
}

# ------------------------------------------------------------------------
# Data Source: aws_iam_policy_document.ecs_custom_doc
# ------------------------------------------------------------------------
# This data source defines a custom IAM policy document for ECS tasks. It includes
# permissions for S3 operations, SSM Parameter Store access, and MediaConvert actions.
# ------------------------------------------------------------------------
data "aws_iam_policy_document" "ecs_custom_doc" {
  
  # 1) S3 permissions
  statement {
    actions   = ["s3:GetObject", "s3:PutObject"]  # Allow S3 GetObject and PutObject actions
    resources = ["arn:aws:s3:::${var.s3_bucket_name}/*"]  # Apply permissions to all objects in the specified S3 bucket
  }

  # 2) SSM Parameter Store permissions
  statement {
    actions = [
      "ssm:GetParameter",          # Allow retrieving a single parameter
      "ssm:GetParameters",         # Allow retrieving multiple parameters
      "ssm:GetParameterHistory"    # Allow retrieving the history of a parameter
    ]
    resources = [
      var.rapidapi_ssm_parameter_arn  # ARN of the specific SSM parameter to grant access to
    ]
  }

  # 3) MediaConvert permissions
  statement {
    actions = [
      "mediaconvert:CreateJob",  # Allow creating MediaConvert jobs
      "mediaconvert:GetJob",     # Allow retrieving MediaConvert job details
      "mediaconvert:ListJobs"    # Allow listing MediaConvert jobs
    ]
    resources = ["*"]  # MediaConvert requires "*" for resource ARN as it manages multiple resources
  }
}

# ------------------------------------------------------------------------
# Resource: aws_iam_policy.ecs_custom_policy
# ------------------------------------------------------------------------
# This IAM policy resource is created using the custom policy document defined
# in ecs_custom_doc. It encapsulates the permissions needed by ECS tasks beyond
# the standard execution role policies.
# ------------------------------------------------------------------------
resource "aws_iam_policy" "ecs_custom_policy" {
  name   = "${var.project_name}-ecs-custom-policy"  # Name of the custom IAM policy, incorporating the project name variable
  policy = data.aws_iam_policy_document.ecs_custom_doc.json  # Attach the custom policy JSON
}

# ------------------------------------------------------------------------
# Resource: aws_iam_role_policy_attachment.ecs_custom_attach
# ------------------------------------------------------------------------
# This resource attaches the custom ECS policy (ecs_custom_policy) to the
# ECS task execution role (ecs_task_execution_role), granting the additional
# permissions defined in the custom policy.
# ------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "ecs_custom_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name  # The name of the IAM role to attach the custom policy to
  policy_arn = aws_iam_policy.ecs_custom_policy.arn        # ARN of the custom IAM policy to attach
}

# ------------------------------------------------------------------------
# Data Source: aws_iam_policy_document.mediaconvert_trust
# ------------------------------------------------------------------------
# This data source defines the trust relationship policy that allows MediaConvert
# to assume the IAM role. It specifies that the service "mediaconvert.amazonaws.com"
# is allowed to perform the "sts:AssumeRole" action.
# ------------------------------------------------------------------------
data "aws_iam_policy_document" "mediaconvert_trust" {
  statement {
    actions = ["sts:AssumeRole"]  # Allow the action sts:AssumeRole

    principals {
      type        = "Service"                      # Specify the type of principal as Service
      identifiers = ["mediaconvert.amazonaws.com"] # The service allowed to assume the role
    }
  }
}

# ------------------------------------------------------------------------
# Resource: aws_iam_role.mediaconvert_role
# ------------------------------------------------------------------------
# This IAM role is created for AWS MediaConvert. It uses the trust policy
# defined in the mediaconvert_trust data source to allow MediaConvert to assume this role.
# ------------------------------------------------------------------------
resource "aws_iam_role" "mediaconvert_role" {
  name               = "${var.project_name}-mediaconvert-role"  # Name of the IAM role, incorporating the project name variable
  assume_role_policy = data.aws_iam_policy_document.mediaconvert_trust.json  # Attach the trust policy JSON to the role
}

# ------------------------------------------------------------------------
# Data Source: aws_iam_policy_document.mediaconvert_policy_doc
# ------------------------------------------------------------------------
# This data source defines a custom IAM policy document for MediaConvert. It includes
# permissions for S3 operations and CloudWatch Logs.
# ------------------------------------------------------------------------
data "aws_iam_policy_document" "mediaconvert_policy_doc" {
  
  # Statement for S3 permissions
  statement {
    actions   = ["s3:GetObject", "s3:PutObject"]  # Allow S3 GetObject and PutObject actions
    resources = ["arn:aws:s3:::${var.s3_bucket_name}/*"]  # Apply permissions to all objects in the specified S3 bucket
  }

  # Statement for CloudWatch Logs permissions
  statement {
    actions   = [
      "logs:CreateLogStream",  # Allow creating log streams in CloudWatch Logs
      "logs:PutLogEvents"      # Allow putting log events into CloudWatch Logs
    ]
    resources = [
      "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/ecs/${var.project_name}/*"
      # ARN for the specific CloudWatch Logs log group associated with the ECS project
    ]
  }
}

# ------------------------------------------------------------------------
# Resource: aws_iam_policy.mediaconvert_policy
# ------------------------------------------------------------------------
# This IAM policy resource is created using the MediaConvert policy document
# defined in mediaconvert_policy_doc. It grants MediaConvert the necessary
# permissions to interact with S3 and CloudWatch Logs.
# ------------------------------------------------------------------------
resource "aws_iam_policy" "mediaconvert_policy" {
  name   = "${var.project_name}-mediaconvert-s3-logs"  # Name of the MediaConvert IAM policy, incorporating the project name variable
  policy = data.aws_iam_policy_document.mediaconvert_policy_doc.json  # Attach the MediaConvert policy JSON
}

# ------------------------------------------------------------------------
# Resource: aws_iam_role_policy_attachment.mediaconvert_attach
# ------------------------------------------------------------------------
# This resource attaches the MediaConvert IAM policy (mediaconvert_policy) to the
# MediaConvert IAM role (mediaconvert_role), granting the necessary permissions.
# ------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "mediaconvert_attach" {
  role       = aws_iam_role.mediaconvert_role.name   # The name of the IAM role to attach the MediaConvert policy to
  policy_arn = aws_iam_policy.mediaconvert_policy.arn # ARN of the MediaConvert IAM policy to attach
}

# ------------------------------------------------------------------------
# Data Source: aws_caller_identity.current
# ------------------------------------------------------------------------
# (Assumed) Data source to retrieve the current AWS account ID. This is used
# in the mediaconvert_policy_doc to specify the ARN for CloudWatch Logs.
# ------------------------------------------------------------------------
data "aws_caller_identity" "current" {}
