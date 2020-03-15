data "cloudflare_zones" "zone" {
  filter {
    name          = var.domain
  }
}

resource "cloudflare_record" "hashistack" {
  for_each = toset(var.hostname)
  zone_id  = element(data.cloudflare_zones.zone.zones, 0).id
  name     = each.key
  value    = aws_instance.hashistack[var.subnet_ids[0]].public_ip
  type     = "A"
  proxied  = false
}
