resource "aws_dynamodb_table" "flavios_records" {
  name         = "flaviosRecords"
  billing_mode = "PAY_PER_REQUEST"

  hash_key  = "recordID"   # partition key
  range_key = "timestamp"   # sort key; store ISO-8601 or epoch

  attribute {
    name = "recordID"
    type = "S"
  }
  attribute {
    name = "timestamp"
    type = "S"
  }  

  tags = {
    Name        = "flaviosRecords"
    Environment = "dev"
  }
}
