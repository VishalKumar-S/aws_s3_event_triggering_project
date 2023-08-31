#!/bin/bash

#debugging mode
set -x

##########################
#Author  : Vishal Kumar. S
#Date    : 30-08-2023
#version : v1
#Project : aws s3 notification triggering
##########################

#aws account id variable
aws_account_id=$(aws sts get-caller-identity --query 'Account' --output text)

#setting up aws variables
aws_region="us-east-1"
bucket_name="Vishal Kumar-bucket"
lambda_func_name="s3 lambda function"
role_name="s3-lamba-sns"
email_address="vk28.02.2004@gmail.com"

#create IAM role
role_response=$(aws iam create-role --role-name s3-lamba-sns --assume-role-policy-document '{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": ["lambda.amazonaws.com",
                    "s3.amazonaws.com",
                    "sns.amazonaws.com"
                    ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
  }'
  )
#extracting the role ARN from the JSON response
role_arn=$(echo "role_response" | jq -r '.Role.Arn')

#print the role
echo "The ARN Role is: $role_arn"
#attaching neccessary policy files of iam user
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AWSLambda_FullAccess --role-name $role_name 
aws iam attach-role-policy --policy-arn arn:aws:iam::aws:policy/AmazonSNSFullAccess --role-name $role_name 

#create s3 bucket
bucket_output=$(aws s3api create-bucket --bucket "$bucket_name" --region "$aws_region")

#print the s3 bucket
echo "Bucket output : $bucket_output"

#creating a zip file for lambda function
zip -r s3-lambda-function.zip ./s3-lambda-function

sleep 5
#create a lambda function
aws lambda create-function \
--region "$aws_region"\
--function-name "$lambda_func_name" \
--zip-file "fileb://s3-lambda-function.zip"\
--handler "s3-lambda-function/s3-lambda-function.lambda_handler" \
--runtime "python3.8" \
--role "arn:aws:iam::$aws_account_id:role/$role_name" \
--timeout 30\
--memory-size 128

#add invoke permissions to the s3 bucket to invoke lambda
aws lambda add-permission \
    --function-name "$lambda_func_name" \
    --action lambda:InvokeFunction \
    --statement-id "s3-lambda-sns" \
    --principal s3.amazonaws.com \
    --source-arn "arn:aws:s3:::$bucket_name"

#create s3 event trigger for the lambda function
LambdaFunctionArn="arn:aws:lambda:us-east-1:$aws_account_id:function:s3-lambda-function"
aws s3api put-bucket-notification-configuration \
  --region "$aws_region" \
  --bucket "$bucket_name" \
  --notification-configuration '{
    "LambdaFunctionConfigurations": [{
        "LambdaFunctionArn": "'"$LambdaFunctionArn"'",
        "Events": ["s3:ObjectCreated:*"]
    }]
}'

#create sns topic 
topic_arn=$(aws sns create-topic --name s3-lambda-sns --output json | jq -r '.TopicArn')

#print the sns topic
echo "SNS topic ARN: $topic_arn"

#add SNS subscribe
aws sns subscribe \
    --topic-arn "$topic_arn" \
    --protocol email \
    --notification-endpoint "$email_address"

#publish SNS
aws sns publish \
    --topic-arn "$topic_arn" \
    --subject "A new object created in s3 bucket" \
    --message "Hey there! This is Vishal Kumar.S, this is my s3-event-triggering-project"
