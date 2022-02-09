resource "aws_iam_role" "nodes" {
  name = "eks-node-group-nodes"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.nodes.name
}

resource "aws_eks_node_group" "private-launch-temp-nodes" {
  cluster_name    = aws_eks_cluster.mm.name
  node_group_name = "private-launch-temp-nodes"
  node_role_arn   = aws_iam_role.nodes.arn

  subnet_ids = var.node_subnet_ids

  scaling_config {
    desired_size = 2
    max_size     = 5
    min_size     = 0
  }
  
  update_config {
    max_unavailable = 1
  }  

  launch_template {
   name = aws_launch_template.mm_eks_launch_template.name
   version = aws_launch_template.mm_eks_launch_template.latest_version
  }

  depends_on = [
    aws_iam_role_policy_attachment.nodes-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodes-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodes-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.nodes-AmazonSSMManagedInstanceCore,
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "mm_eks_launch_template" {
  name = "mm_eks_launch_template"

  #vpc_security_group_ids = [var.your_security_group.id, aws_eks_cluster.your-eks-cluster.vpc_config[0].cluster_security_group_id]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = 20
      volume_type = "gp2"
    }
  }

  image_id = "ami-0a0d313506d35fec9"
  instance_type = "t3.medium"
  user_data = base64encode(<<-EOF
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="==MYBOUNDARY=="
--==MYBOUNDARY==
Content-Type: text/x-shellscript; charset="us-ascii"
#!/bin/bash
/etc/eks/bootstrap.sh mm
--==MYBOUNDARY==--\
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "MM-EKS-MANAGED-NODE"
    }
  }
}
