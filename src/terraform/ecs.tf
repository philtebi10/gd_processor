# ecs.tf

# ------------------------------------------------------------------------
# Resource: aws_ecs_cluster.this
# ------------------------------------------------------------------------
# This resource creates an Amazon Elastic Container Service (ECS) cluster.
# An ECS cluster is a logical grouping of tasks or services.
# ------------------------------------------------------------------------
resource "aws_ecs_cluster" "this" {
  # Name of the ECS cluster, combining the project name variable with a descriptive suffix
  name = "${var.project_name}-cluster"
}

# ------------------------------------------------------------------------
# Resource: aws_cloudwatch_log_group.ecs_log_group
# ------------------------------------------------------------------------
# This resource creates a CloudWatch Logs log group for storing ECS task logs.
# Log groups are containers for log streams, which are sequences of log events.
# ------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  # Name of the log group, following the pattern /ecs/{project_name}
  name              = "/ecs/${var.project_name}"
  
  # Retention period for the logs in days; logs older than this will be automatically deleted
  retention_in_days = 7
}

# ------------------------------------------------------------------------
# Resource: aws_ecs_task_definition.this
# ------------------------------------------------------------------------
# This resource defines an ECS task definition, which specifies how ECS tasks should be launched.
# It includes configurations like CPU and memory requirements, network settings, and container definitions.
# ------------------------------------------------------------------------
resource "aws_ecs_task_definition" "this" {
  # Family name for the task definition, combining the project name variable with a descriptive suffix
  family                   = "${var.project_name}-task"
  
  # Number of CPU units reserved for the task (e.g., 256 CPU units = 0.25 vCPU)
  cpu                      = 256
  
  # Amount of memory (in MiB) reserved for the task
  memory                   = 512
  
  # Network mode for the containers in the task; "awsvpc" provides each task with its own network interface
  network_mode             = "awsvpc"
  
  # Specifies that the task definition is compatible with AWS Fargate
  requires_compatibilities = ["FARGATE"]
  
  # ARN of the IAM role that grants permissions to the ECS tasks for AWS services (execution role)
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  
  # ARN of the IAM role that grants permissions to the ECS tasks for accessing AWS resources (task role)
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn

  # Container definitions for the task, loaded from an external template file
  container_definitions = templatefile("${path.module}/container_definitions.tpl", {
    # URL of the Docker image stored in the ECR repository, tagged as 'latest'
    ecr_image_url               = "${aws_ecr_repository.this.repository_url}:latest"
    
    # Name of the CloudWatch Logs log group for container logs
    log_group_name              = aws_cloudwatch_log_group.ecs_log_group.name
    
    # AWS region where the resources are deployed
    aws_region                  = var.aws_region
    
    # Name of the S3 bucket used for storing highlights
    bucket_name                 = var.s3_bucket_name
    
    # ARN of the SSM Parameter Store parameter containing the RapidAPI key
    rapidapi_ssm_parameter_arn  = var.rapidapi_ssm_parameter_arn
    
    # Endpoint URL for AWS MediaConvert service
    mediaconvert_endpoint       = var.mediaconvert_endpoint
    
    # ARN of the IAM role for AWS MediaConvert
    mediaconvert_role_arn       = var.mediaconvert_role_arn
  })
}

# ------------------------------------------------------------------------
# Resource: aws_ecs_service.this
# ------------------------------------------------------------------------
# This resource creates an ECS service, which manages the deployment and scaling of ECS tasks.
# The service ensures that the desired number of task instances are running and handles task placement.
# ------------------------------------------------------------------------
resource "aws_ecs_service" "this" {
  # Name of the ECS service, combining the project name variable with a descriptive suffix
  name            = "${var.project_name}-service"
  
  # ID of the ECS cluster where the service will run
  cluster         = aws_ecs_cluster.this.id
  
  # ARN of the ECS task definition to use for tasks launched by the service
  task_definition = aws_ecs_task_definition.this.arn
  
  # Desired number of task instances to keep running
  desired_count   = 1
  
  # Launch type for the service; "FARGATE" runs tasks on AWS Fargate
  launch_type     = "FARGATE"

  # ----------------------------------------------------------------------
  # Nested Block: network_configuration
  # ----------------------------------------------------------------------
  # Configures the networking settings for the ECS service tasks, including
  # subnets, security groups, and whether to assign a public IP address.
  # ----------------------------------------------------------------------
  network_configuration {
    # List of subnet IDs where the tasks will be placed
    subnets          = var.public_subnets
    
    # List of security group IDs to associate with the tasks
    security_groups  = [aws_security_group.ecs_task.id]
    
    # Whether to assign a public IP address to the tasks
    assign_public_ip = true
  }

  # ----------------------------------------------------------------------
  # Nested Block: deployment_controller
  # ----------------------------------------------------------------------
  # Specifies the deployment controller type for the ECS service.
  # The "ECS" type uses the default ECS deployment controller.
  # ----------------------------------------------------------------------
  deployment_controller {
    type = "ECS"
  }
}
