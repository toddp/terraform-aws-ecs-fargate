# ----------------------------------------
# Create a ecs service using fargate
# ----------------------------------------
variable access_key {}
variable secret_key {}
variable region {}

provider "aws" {
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
  region     = "${var.region}"
}


resource "aws_ecs_cluster" "cluster" {
  name = "example-ecs-cluster"
}

data "aws_vpc" "main" {
  default = true
}

data "aws_subnet_ids" "main" {
  vpc_id = "${data.aws_vpc.main.id}"
}

module "fargate_alb" {
  source  = "telia-oss/loadbalancer/aws"
  version = "0.1.0"

  name_prefix = "example-ecs-cluster"
  type        = "application"
  internal    = "false"
  vpc_id      = "${data.aws_vpc.main.id}"
  subnet_ids  = ["${data.aws_subnet_ids.main.ids}"]

  tags {
    environment = "test"
    terraform   = "true"
  }
}

resource "aws_lb_listener" "alb" {
  load_balancer_arn = "${module.fargate_alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${module.fargate.target_group_arn}"
    type             = "forward"
  }
}
resource "aws_lb_listener" "alb_slave_5557" {
  load_balancer_arn = "${module.fargate_alb.arn}"
  port              = "5557"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${module.fargate.target_group_arn}"
    type             = "forward"
  }
}
resource "aws_lb_listener" "alb_slave_5567" {
  load_balancer_arn = "${module.fargate_alb.arn}"
  port              = "5567"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${module.fargate.target_group_arn}"
    type             = "forward"
  }
}
resource "aws_lb_listener" "alb_slave_5558" {
  load_balancer_arn = "${module.fargate_alb.arn}"
  port              = "5558"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${module.fargate.target_group_arn}"
    type             = "forward"
  }
}
resource "aws_lb_listener" "alb_slave_5568" {
  load_balancer_arn = "${module.fargate_alb.arn}"
  port              = "5568"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${module.fargate.target_group_arn}"
    type             = "forward"
  }
}



resource "aws_security_group_rule" "task_ingress_8000" {
  security_group_id        = "${module.fargate.service_sg_id}"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = "8089"
  to_port                  = "8089"
  source_security_group_id = "${module.fargate_alb.security_group_id}"
}



resource "aws_security_group_rule" "task_ingress_5557" {
  security_group_id        = "${module.fargate.service_sg_id}"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = "5557"
  to_port                  = "5557"
  source_security_group_id = "${module.fargate_alb.security_group_id}"
}

resource "aws_security_group_rule" "alb_ingress_5557" {
  security_group_id = "${module.fargate_alb.security_group_id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "5557"
  to_port           = "5557"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "task_ingress_5558" {
  security_group_id        = "${module.fargate.service_sg_id}"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = "5558"
  to_port                  = "5558"
  source_security_group_id = "${module.fargate_alb.security_group_id}"
}

resource "aws_security_group_rule" "alb_ingress_5558" {
  security_group_id = "${module.fargate_alb.security_group_id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "5558"
  to_port           = "5558"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "alb_ingress_5567" {
  security_group_id = "${module.fargate_alb.security_group_id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "5567"
  to_port           = "5567"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

resource "aws_security_group_rule" "task_ingress_5568" {
  security_group_id        = "${module.fargate.service_sg_id}"
  type                     = "ingress"
  protocol                 = "tcp"
  from_port                = "5568"
  to_port                  = "5568"
  source_security_group_id = "${module.fargate_alb.security_group_id}"
}

resource "aws_security_group_rule" "alb_ingress_80" {
  security_group_id = "${module.fargate_alb.security_group_id}"
  type              = "ingress"
  protocol          = "tcp"
  from_port         = "80"
  to_port           = "80"
  cidr_blocks       = ["0.0.0.0/0"]
  ipv6_cidr_blocks  = ["::/0"]
}

module "fargate" {
  source = "../../"

  name_prefix          = "example-app"
  vpc_id               = "${data.aws_vpc.main.id}"
  private_subnet_ids   = "${data.aws_subnet_ids.main.ids}"
  cluster_id           = "${aws_ecs_cluster.cluster.id}"
  #task_container_image = "crccheck/hello-world:latest"
  task_container_image = "pinkatron/locust:latest"

  // public ip is needed for default vpc, default is false
  task_container_assign_public_ip = "true"

  // port, default protocol is HTTP
  task_container_port = "8089"
  task_container_port_slave = "5557"
  task_container_port_slave2 = "5558"
  task_container_port_slave3 = "5567"
  task_container_port_slave4 = "5568"

  health_check {
    port = "traffic-port"
    path = "/"
  }

  tags {
    environment = "test"
    terraform   = "true"
  }
  desired_count = 2
  lb_arn = "${module.fargate_alb.arn}"
  task_container_command  = ["--master-bind-port", "5567"]
  task_container_command_slave = ["--master-host", "http://example-ecs-cluster-alb-398518833.us-west-2.elb.amazonaws.com", "--master-port", "5567"]

}