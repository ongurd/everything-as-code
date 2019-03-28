data "aws_subnet_ids" "private" {
  vpc_id = "${var.vpc_id}"
  tags {
    Tier = "Private"
  }
}

# Worker Node Role
resource "aws_iam_role" "voting_worker_node" {
  name = "${var.project_name}-worker-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Worker Role Associations
resource "aws_iam_role_policy_attachment" "voting_worker_node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = "${aws_iam_role.voting_worker_node.name}"
}

resource "aws_iam_role_policy_attachment" "voting_worker_node_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = "${aws_iam_role.voting_worker_node.name}"
}

resource "aws_iam_role_policy_attachment" "voting_worker_node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = "${aws_iam_role.voting_worker_node.name}"
}

# Worker Node Instance Profile
resource "aws_iam_instance_profile" "voting_worker_node" {
  name = "${var.project_name}-worker-node"
  role = "${aws_iam_role.voting_worker_node.name}"
}

# Bootsrap Script
locals {
  worker_node_userdata = <<USERDATA
#!/bin/bash

set -o xtrace
/etc/eks/bootstrap.sh ${var.project_name}
USERDATA
}

# Launch Configuration
resource "aws_launch_configuration" "voting_worker_node" {
  associate_public_ip_address = true
  iam_instance_profile        = "${aws_iam_instance_profile.voting_worker_node.name}"
  image_id                    = "${var.eks_worker_node_ami}"
  instance_type               = "${var.eks_worker_node_instance_type}"
  name_prefix                 = "${var.project_name}-worker-node"
  security_groups             = ["${var.worker_node_security_group_id}"]
  user_data_base64            = "${base64encode(local.worker_node_userdata)}"
  key_name                    = "${var.eks_worker_node_key}"

  lifecycle {
    create_before_destroy = true
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "voting" {
  # desired_capacity     = "${var.eks_desired_node_count}"
  launch_configuration = "${aws_launch_configuration.voting_worker_node.id}"
  max_size             = "${var.eks_max_node_count}"
  min_size             = "${var.eks_min_node_count}"
  name                 = "${var.project_name}"
  vpc_zone_identifier  = ["${data.aws_subnet_ids.private.ids}"]

  tag {
    key                 = "Name"
    value               = "${var.project_name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.project_name}"
    value               = "owned"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "auto-discovery"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.project_name}"
    value               = "auto-discovery"
    propagate_at_launch = true
  }
}

# Required Kubernetes Configuration to Join Worker Nodes
locals {
  config-map-aws-auth = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.voting_worker_node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH
}

# EFS
resource "aws_efs_file_system" "voting" {
  creation_token = "${var.project_name}"

  tags {
    Name = "${var.project_name}"
  }
}

resource "aws_efs_mount_target" "voting" {
  count = 2

  file_system_id = "${aws_efs_file_system.voting.id}"
  subnet_id      = "${element(data.aws_subnet_ids.private.ids, count.index)}"
}

# Cluster AutoScaler Role
resource "aws_iam_policy" "cluster_autoscaler" {
  name        = "cluster_autoscaler_policy"
  path        = "/"
  description = "Policy to use for autoscaling of EKS worker nodes"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
              "autoscaling:DescribeAutoScalingGroups",
              "autoscaling:DescribeAutoScalingInstances",
              "autoscaling:SetDesiredCapacity",
              "autoscaling:DescribeLaunchConfigurations",
              "autoscaling:DescribeTags",
              "autoscaling:TerminateInstanceInAutoScalingGroup"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_policy_attachment" "auto_scaling_attachment" {
  name       = "auto-scaling-attachment"
  roles      = ["${aws_iam_role.voting_worker_node.name}"]
  policy_arn = "${aws_iam_policy.cluster_autoscaler.arn}"
}

output "config-map-aws-auth" {
  value = "${local.config-map-aws-auth}"
}
