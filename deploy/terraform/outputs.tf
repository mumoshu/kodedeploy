output "bucket" {
  value = "${aws_s3_bucket.codedeploy_app_bundles.id}"
}
