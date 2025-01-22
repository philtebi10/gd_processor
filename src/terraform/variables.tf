# variables.tf

variable "aws_region" {
  type        = string
  description = "AWS region to deploy resources."
}

variable "project_name" {
  type        = string
  description = "Name of the project."
}

variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket for highlights."
}

variable "ecr_repository_name" {
  type        = string
  description = "Name of the ECR repository."
}

# VPC ID
variable "vpc_id" {
  type        = string
  description = "ID of the VPC."
}

# Subnet IDs: one public, one private
variable "public_subnets" {
  type        = list(string)
  description = "List of public subnet IDs for ECS tasks or NAT Gateways."
}

variable "private_subnets" {
  type        = list(string)
  description = "List of private subnet IDs for ECS tasks without direct public IPs."
}

# Internet Gateway & Route Tables
variable "igw_id" {
  type        = string
  description = "Internet Gateway ID for the public subnet."
}

variable "public_route_table_id" {
  type        = string
  description = "Public route table ID."
}

variable "private_route_table_id" {
  type        = string
  description = "Private route table ID."
}

# SSM Parameter Store ARN for RapidAPI key
variable "rapidapi_ssm_parameter_arn" {
  type        = string
  description = "ARN of the SSM Parameter Store secret for RapidAPI key."
}

# MediaConvert Endpoint URL (leave blank for auto-discovery)
variable "mediaconvert_endpoint" {
  type        = string
  description = "MediaConvert endpoint URL. Leave blank to let Boto3 auto-discover."
}

# MediaConvert IAM Role ARN
variable "mediaconvert_role_arn" {
  type        = string
  description = "ARN of the MediaConvert IAM role."
}
