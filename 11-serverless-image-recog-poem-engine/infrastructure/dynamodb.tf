# -------------------------------
# DynamoDB Table for Poem Results
# -------------------------------
resource "aws_dynamodb_table" "poem_results" {
  name           = "${var.project_name}-poem-results"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "poemId"

  attribute {
    name = "poemId"
    type = "S"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = var.tags
}