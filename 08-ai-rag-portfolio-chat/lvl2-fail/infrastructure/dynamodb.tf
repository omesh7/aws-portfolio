resource "aws_dynamodb_table" "document_table" {
  name         = "${var.project_name}-document-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userid"
  range_key    = "documentid"

  attribute {
    name = "userid"
    type = "S"
  }

  attribute {
    name = "documentid"
    type = "S"
  }

  attribute {
    name = "docstatus"
    type = "S"
  }

  global_secondary_index {
    name            = "UserByStatusIndex"
    hash_key        = "userid"
    range_key       = "docstatus"
    projection_type = "ALL"
  }
  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_dynamodb_table" "memory_table" {
  name         = "${var.project_name}-memory-table"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "SessionId"
  range_key    = "History"

  attribute {
    name = "SessionId"
    type = "S"
  }
  attribute {
    name = "History"
    type = "S"
  }
  lifecycle {
    prevent_destroy = false
  }
}
