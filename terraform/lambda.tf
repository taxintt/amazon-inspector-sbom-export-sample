resource "lambdazip_file" "bref" {
  base_dir      = "${path.module}/../lambda/bref"
  sources       = ["**"]
  output        = "${path.module}/.build/bref.zip"
  before_create = "sh -c 'docker run --rm -v \"$(pwd):/app\" -w /app composer:2 install --no-dev --no-interaction --no-progress'"
  triggers = {
    for f in ["index.php", "composer.json"] :
    f => filesha256("${path.module}/../lambda/bref/${f}")
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name_prefix}-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:${local.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "bref" {
  function_name    = "sbom-php-bref-layer"
  role             = aws_iam_role.lambda.arn
  runtime          = "provided.al2023"
  handler          = "index.php"
  layers           = [var.bref_layer_arn]
  filename         = lambdazip_file.bref.output
  source_code_hash = lambdazip_file.bref.base64sha256

  depends_on = [aws_inspector2_enabler.this]
}

resource "lambdazip_file" "python" {
  base_dir = "${path.module}/../lambda/python"
  sources  = ["**"]
  output   = "${path.module}/.build/python.zip"
  triggers = {
    "index.py" = filesha256("${path.module}/../lambda/python/index.py")
  }
}

resource "aws_lambda_function" "python" {
  function_name    = "sbom-python-control"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.13"
  handler          = "index.handler"
  filename         = lambdazip_file.python.output
  source_code_hash = lambdazip_file.python.base64sha256

  depends_on = [aws_inspector2_enabler.this]
}
