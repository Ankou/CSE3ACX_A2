#!/bin/bash

# Create log file
runDate=$(date +"%Y%m%d-%H%M")
logFile=~/$0-$runDate
echo "Script Starting @ $runDate" > $logFile

# Create VPC
aws ec2 create-vpc --cidr-block 172.17.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=a2VPC-SECOND},{Key=Project,Value="CSE3ACX-A2"}]'  --query Vpc.VpcId --output text


# CLEAN UP
# List all resources with this tag
#    aws resourcegroupstaggingapi get-resources  --tag-filters Key=Project,Values=CSE3ACX-A2 

# Create JSON file to cleanup
#BUCKET_NAME=testbucket
#OBJECT_NAME=testworkflow-2.0.1.jar
#TARGET_LOCATION=/opt/test/testworkflow-2.0.1.jar

#JSON_STRING=$( jq -n \
#                  --arg vpc-id "$VPC" \
#                  --arg on "$OBJECT_NAME" \
#                  --arg tl "$TARGET_LOCATION" \
#                  '{VPC-ID: $vpc-id, objectname: $on, targetlocation: $tl}' )

#echo $JSON_STRING

