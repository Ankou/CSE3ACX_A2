#!/bin/bash

# Shell script to clean up resources

VPC=$(jq -r '."VPC-ID"' resources.json )

aws ec2 delete-vpc --vpc-id $VPC