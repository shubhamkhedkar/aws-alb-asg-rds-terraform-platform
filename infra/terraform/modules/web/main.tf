data "aws_ssm_parameter" "ami" {
  name = var.ami_ssm_parameter
}

data "aws_region" "current" {}

locals {
  user_data = templatefile("${path.module}/templates/user-data.sh.tftpl", {
    region        = data.aws_region.current.region
    app_image     = var.app_image
    app_port      = var.app_port
    db_host       = var.db_host
    db_port       = var.db_port
    db_name       = var.db_name
    db_secret_arn = var.db_secret_arn
  })
}

resource "aws_launch_template" "web" {
  name_prefix   = "${var.name}-web-"
  image_id      = nonsensitive(data.aws_ssm_parameter.ami.value)
  instance_type = var.instance_type
  user_data     = base64encode(local.user_data)

  update_default_version = true
  vpc_security_group_ids = [var.web_security_group_id]

  iam_instance_profile {
    arn = aws_iam_instance_profile.web.arn
  }

  # IMDSv2 only, and a hop limit of 1 so containers cannot reach instance credentials.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "disabled"
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = 20
      volume_type           = "gp3"
      encrypted             = true
      kms_key_id            = var.kms_key_arn
      delete_on_termination = true
    }
  }

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "${var.name}-web" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(var.tags, { Name = "${var.name}-web" })
  }

  tags = var.tags
}

resource "aws_autoscaling_group" "web" {
  name_prefix               = "${var.name}-web-"
  vpc_zone_identifier       = var.app_subnet_ids
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  max_size                  = var.max_size
  target_group_arns         = [aws_lb_target_group.app.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 180
  default_instance_warmup   = 120

  launch_template {
    id      = aws_launch_template.web.id
    version = aws_launch_template.web.latest_version
  }

  # Rolling replacement whenever the launch template (image tag, AMI, user data) changes.
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
      auto_rollback          = true
    }
  }

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupTerminatingInstances",
  ]

  dynamic "tag" {
    for_each = merge(var.tags, { Name = "${var.name}-web" })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

resource "aws_autoscaling_policy" "cpu" {
  name                   = "${var.name}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.web.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target_percent
  }
}
