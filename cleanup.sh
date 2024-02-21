#!/bin/bash

# Shell script to clean up resources
resources=~/resources.json

VPC=$(jq -r '."VPC-ID"' $resources )

aws ec2 delete-vpc --vpc-id $VPC

rm -f $resources