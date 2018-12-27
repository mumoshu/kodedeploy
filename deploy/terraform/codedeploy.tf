resource "aws_codedeploy_app" "main" {
  name = "${var.app_name}"
}

resource "aws_codedeploy_deployment_group" "main" {
  app_name              = "${aws_codedeploy_app.main.name}"
  deployment_group_name = "${var.app_name}-dg"
  service_role_arn      = "${var.codedeploy_service_role_arn == "" ? aws_iam_role.codedeploy_service.arn : var.codedeploy_service_role_arn}"
  # Or e.g. CodeDeployDefault.OneAtATime
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
}

resource "aws_iam_role" "codedeploy_service" {
#  name = "codedeploy-service"

  description = "Allows CodeDeploy to call AWS services such as Auto Scaling on your behalf."

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "codedeploy.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "codedeploy_service" {
  role       = "${aws_iam_role.codedeploy_service.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}
