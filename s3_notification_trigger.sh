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
                    "s3.amazonaws.com:,
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

#attaching neccessary policy files of iam user
aws iam attach-user-policy --policy-arn arn:aws:iam:ACCOUNT-ID:aws:policy/AdministratorAccess --user-name Alice

