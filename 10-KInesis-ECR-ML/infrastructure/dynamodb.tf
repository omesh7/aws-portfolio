resource "aws_dynamodb_table" "anomaly_data" {
  name         = "anomaly-stream-records"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Project = "kinesis-ecr-10-app"
  }
}
