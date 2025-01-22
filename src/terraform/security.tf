# security.tf

# Define an AWS Security Group resource named "ecs_task"
resource "aws_security_group" "ecs_task" {
  # Set the name of the security group using the project name variable and a descriptive suffix
  name        = "${var.project_name}-ecs-task-sg"
  
  # Provide a description for the security group to clarify its purpose
  description = "Security group for ECS tasks"
  
  # Associate the security group with a specific VPC using the VPC ID variable
  vpc_id      = var.vpc_id

  # Define ingress (inbound) rules for the security group
  ingress {
    # Specify the starting port for the inbound rule (443 for HTTPS)
    from_port   = 443
    
    # Specify the ending port for the inbound rule (443 for HTTPS)
    to_port     = 443
    
    # Define the protocol for the inbound rule (TCP)
    protocol    = "tcp"
    
    # Specify the CIDR blocks that are allowed to send traffic to the defined ports and protocol
    cidr_blocks = ["0.0.0.0/0"]  # Allow HTTPS traffic from any IP address; adjust as needed for security
  }

  # Define egress (outbound) rules for the security group
  egress {
    # Specify the starting port for the outbound rule (0 means all ports)
    from_port   = 0
    
    # Specify the ending port for the outbound rule (0 means all ports)
    to_port     = 0
    
    # Define the protocol for the outbound rule ("-1" means all protocols)
    protocol    = "-1"  # Allow all outbound traffic
    
    # Specify the CIDR blocks that are allowed to receive traffic from the defined ports and protocol
    cidr_blocks = ["0.0.0.0/0"]  # Allow all outbound traffic to any IP address
  }
}
