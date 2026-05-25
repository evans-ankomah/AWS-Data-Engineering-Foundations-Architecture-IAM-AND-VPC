data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [var.trusted_service]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.name
  description        = var.description
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = toset(concat(var.managed_policy_arns, var.custom_policy_arns))

  role       = aws_iam_role.this.name
  policy_arn = each.value
}
