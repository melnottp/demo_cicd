data "template_cloudinit_config" "config" {
  dynamic "part" {
    for_each = length(var.cloud_init_path) == 0 ? toset([]) : toset(fileset(var.cloud_init_path, "*.{yml,yaml}"))
    content {
      content_type = "text/cloud-config"
      content      = file(part.value)
    }
  }
}
