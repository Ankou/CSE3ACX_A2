#!/bin/bash

# Shell script to clean up resources
resources=~/resources.json

VPC=$( jq -r '."VPC-ID"' $resources )
subnet0=$( jq -r '."Subnet0"' $resources )

aws ec2 delete-subnet --subnet-id $subnet0
aws ec2 delete-vpc --vpc-id $VPC

rm -f $resources
rm -f ~/.ssh/CSE3ACX-A2-key-pair.pem