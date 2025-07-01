# import {
#   id = "07-receipt-processor-aws-portfolio"
#   to = aws_s3_bucket.uploads_bucket
# }

# import {
#   id = "07-automated-receipt-processor"
#   to = aws_lambda_function.process_receipt
# }

# import {
#   id = "lambda-receipt-processor-role-07-aws-portfolio"
#   to = aws_iam_role.lambda_exec
# }

# import {
#   id = "arn:aws:sns:ap-south-1:982534384941:ReceiptNotifications"
#   to = aws_sns_topic.reciept_notifications
# }

# import {
#     id = "arn:aws:dynamodb:ap-south-1:982534384941:table/Receipts"
#     to = aws_dynamodb_table.receipts_table
# }

