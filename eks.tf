resource "aws_iam_role" "mm" {
  name = "eks-cluster-mm"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "mm-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.mm.name
}

resource "aws_eks_cluster" "mm" {
  name     = "mm"
  role_arn = aws_iam_role.mm.arn

  vpc_config {
    subnet_ids = var.cluster_subnet_ids
  }

  depends_on = [aws_iam_role_policy_attachment.mm-AmazonEKSClusterPolicy]
}
