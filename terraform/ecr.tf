locals {
  ecr_repositories = toset(["official-8.4.26-app", "alpine-php84"])
}

resource "aws_ecr_repository" "this" {
  for_each = local.ecr_repositories

  name                 = each.key
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  depends_on = [aws_ecr_registry_scanning_configuration.this]
}
