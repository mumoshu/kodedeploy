resource "aws_s3_bucket" "codedeploy_app_bundles" {
  acl    = "private"

  tags = {
    "kodedeployenv" = "${var.env}"
  }
}
