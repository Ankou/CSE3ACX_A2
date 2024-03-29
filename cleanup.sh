#!/bin/bash

# Shell script to clean up resources
resources=~/resources.json

VPC=$( jq -r '."VPC-ID"' $resources )
subnet0=$( jq -r '."Subnet0"' $resources )
subnet1=$( jq -r '."Subnet1"' $resources )
PubRouteTable=$( jq -r '."PubRouteTable"' $resources )
internetGateway=$( jq -r '."internetGateway"' $resources )
rtbassoc=$( aws ec2 describe-route-tables --filters 'Name=vpc-id,Values='$VPC | jq -r '."RouteTables"[]."Associations"[]."RouteTableAssociationId"' )
webAppSG=$( jq -r '."webAppSG"' $resources )
ec2Instance=$( jq -r '."ec2ID"' $resources )
eipalloc=$( jq -r '."eipalloc"' $resources )

# Delete EC2 instance
aws ec2 terminate-instances --instance-ids $ec2Instance | grep nothing

ec2status=$( aws ec2 describe-instances --instance-ids $ec2Instance --query 'Reservations[].Instances[].State.Name' --output text  )

while [ $ec2status != "terminated" ]
do
  echo Status: $ec2status trying again in 10 seconds
  ec2status=$( aws ec2 describe-instances --instance-ids $ec2Instance --query 'Reservations[].Instances[].State.Name' --output text  )
  sleep 10
done

# Delete RDS Subnet group
aws rds delete-db-subnet-group --db-subnet-group-name mysubnetgroup

# Delete subnet
aws ec2 delete-subnet --subnet-id $subnet0
aws ec2 delete-subnet --subnet-id $subnet1

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

# Release elastic IP
aws ec2 release-address --allocation-id $eipalloc

rm -f $resources
rm -f ~/.ssh/CSE3ACX-A2-key-pair.pem