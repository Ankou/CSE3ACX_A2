#!/bin/bash

# Shell script to clean up resources

VPC=$(jq '."VPC-ID"' resources.json )

aws ec2 delete-vpc --vpc-id $VPC