resource "aws_kinesis_stream" "anomaly_stream" {
  name             = "anomaly-stream-${random_id.resource_suffix.hex}"
  shard_count      = 1
  retention_period = 24

  tags = {
    Environment = "dev"
    Project     = "real-time-anomaly"
  }
}

