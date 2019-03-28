data "aws_subnet_ids" "subnets" {
  vpc_id = "${var.vpc_id}"
}

# EKS Role
resource "aws_iam_role" "voting_control_panel" {
  name = "${var.project_name}-control-panel"

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

# EKS Role Associations
resource "aws_iam_role_policy_attachment" "voting_control_panel_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role = "${aws_iam_role.voting_control_panel.name}"
}

resource "aws_iam_role_policy_attachment" "voting_control_panel_AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role = "${aws_iam_role.voting_control_panel.name}"
}

# EKS Cluster
resource "aws_eks_cluster" "voting" {
  name = "${var.project_name}"
  role_arn = "${aws_iam_role.voting_control_panel.arn}"

  vpc_config {
    security_group_ids = ["${var.security_group_id}"]
    subnet_ids = ["${data.aws_subnet_ids.subnets.ids}"]
  }

  depends_on = [
    "aws_iam_role_policy_attachment.voting_control_panel_AmazonEKSClusterPolicy",
    "aws_iam_role_policy_attachment.voting_control_panel_AmazonEKSServicePolicy",
  ]
}

output "endpoint" {
  value = "${aws_eks_cluster.voting.endpoint}"
}
