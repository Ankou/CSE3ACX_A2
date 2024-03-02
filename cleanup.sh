#!/bin/bash

# Shell script to clean up resources
resources=~/resources.json

VPC=$( jq -r '."VPC-ID"' $resources )
subnet0=$( jq -r '."Subnet0"' $resources )
PubRouteTable=$( jq -r '."PubRouteTable"' $resources )
internetGateway=$( jq -r '."internetGateway"' $resources )
rtbassoc=$( aws ec2 describe-route-tables --filters 'Name=vpc-id,Values='$VPC | jq -r '."RouteTables"[]."Associations"[]."RouteTableAssociationId"' )
webAppSG=$( jq -r '."webAppSG"' $resources )
ec2Instance=$( jq -r '."ec2ID"' $resources )

# Delete EC2 instance
aws ec2 terminate-instances --instance-ids $ec2Instance

ec2status=$( aws ec2 describe-instances --instance-ids $ec2Instance --query 'Reservations[].Instances[].State.Name' --output text  )

while [ $ec2status != "terminated" ]
do
  echo Status: $ec2status
  ec2status=$( aws ec2 describe-instances --instance-ids $ec2Instance --query 'Reservations[].Instances[].State.Name' --output text  )
  sleep 2
done

# Delete subnet
aws ec2 delete-subnet --subnet-id $subnet0

# Delete route
aws ec2 delete-route --route-table-id $PubRouteTable --destination-cidr-block 0.0.0.0/0

# Detach internet gateway
aws ec2 detach-internet-gateway --internet-gateway-id $internetGateway --vpc-id $VPC

# Delete internet gateway
aws ec2 delete-internet-gateway --internet-gateway-id $internetGateway

# Disassociate route table
#aws ec2 disassociate-route-table --association-id $rtbassoc

# Delete Segurity Group
aws ec2 delete-security-group --group-id $webAppSG

# Delete VPC
aws ec2 delete-vpc --vpc-id $VPC

# Delete key-pair
aws ec2 delete-key-pair --key-name CSE3ACX-A2-key-pair | grep nothing 

rm -f $resources
rm -f ~/.ssh/CSE3ACX-A2-key-pair.pem