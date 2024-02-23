#!/bin/bash

# Shell script to clean up resources
resources=~/resources.json

VPC=$( jq -r '."VPC-ID"' $resources )
subnet0=$( jq -r '."Subnet0"' $resources )
PubRouteTable=$( jq -r '."PubRouteTable"' $resources )
internetGateway=$( jq -r '."internetGateway"' $resources )
rtbassoc=$( aws ec2 describe-route-tables --filters 'Name=vpc-id,Values='$VPC | jq -r '."RouteTables"[]."Associations"[]."RouteTableAssociationId"' )
webAppSG=$( jq -r '."webAppSG"' $resources )

# Delete subnet
aws ec2 delete-subnet --subnet-id $subnet0

# Delete route
aws ec2 delete-route --route-table-id $PubRouteTable --destination-cidr-block 0.0.0.0/0

# Detach internet gateway
aws ec2 detach-internet-gateway --internet-gateway-id $internetGateway --vpc-id $VPC

# Delete internet gateway
aws ec2 delete-internet-gateway --internet-gateway-id $internetGateway

# Disassociate toute table
aws ec2 disassociate-route-table --association-id $rtbassoc

# Delete Segurity Group
aws ec2 delete-security-group --group-id $webAppSG

# Delete VPC
aws ec2 delete-vpc --vpc-id $VPC

rm -f $resources
rm -f ~/.ssh/CSE3ACX-A2-key-pair.pem