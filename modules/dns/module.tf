# data "aws_route53_zone" "zone" {
#   name = "k8s.kloia.com"
# }
#
# resource "aws_route53_record" "vote" {
#   zone_id = "${data.aws_route53_zone.zone.zone_id}"
#   name    = "vote.k8s.kloia.com"
#   type    = "A"
#   ttl     = "30"
#   records = ["104.31.80.225"]
# }
#
# resource "aws_route53_record" "result" {
#   zone_id = "${data.aws_route53_zone.zone.zone_id}"
#   name    = "result.k8s.kloia.com"
#   type    = "A"
#   ttl     = "30"
#   records = ["104.31.80.225"]
# }

