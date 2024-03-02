#!/bin/bash

# Create log file
runDate=$(date +"%Y%m%d-%H%M")
logFile=~/$0-$runDate
echo "Script Starting @ $runDate" > $logFile

# Create VPC
VPC=$(aws ec2 create-vpc --cidr-block 172.16.0.0/16 --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=a2VPC},{Key=Project,Value="CSE3ACX-A2"}]'  --query Vpc.VpcId --output text)

# Create subnets in the new VPC
subnet0=$(aws ec2 create-subnet --vpc-id "$VPC" --cidr-block 172.16.0.0/24 --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Subnet0 Public}]' --availability-zone us-east-1a --query Subnet.SubnetId --output text)

# Determine the route table id for the VPC
PubRouteTable=$(aws ec2 describe-route-tables --query "RouteTables[?VpcId == '$VPC'].RouteTableId" --output text)

# Update tag
aws ec2 create-tags --resources $PubRouteTable --tags 'Key=Name,Value=Public route Table'

# Create Internet Gateway
internetGateway=$(aws ec2 create-internet-gateway --query InternetGateway.InternetGatewayId --output text)

# Attach gateway to VPC
aws ec2 attach-internet-gateway --vpc-id "$VPC" --internet-gateway-id "$internetGateway"

# Create default route to Internet Gateway
aws ec2 create-route --route-table-id "$PubRouteTable" --destination-cidr-block 0.0.0.0/0 --gateway-id "$internetGateway" --query 'Return' --output text

# Apply Public route table to subnet0
aws ec2 associate-route-table --subnet-id "$subnet0" --route-table-id "$PubRouteTable" --query 'AssociationState.State' --output text

# Obtain public IP address on launch
aws ec2 modify-subnet-attribute --subnet-id "$subnet0" --map-public-ip-on-launch

# Create.ssh folder if it doesn't exist
if [ ! -d ~/.ssh/ ]; then
  mkdir ~/.ssh/
  echo "Creating directory"
fi

# Generate Key Pair
aws ec2 create-key-pair --key-name CSE3ACX-A2-key-pair --query 'KeyMaterial' --output text > ~/.ssh/CSE3ACX-A2-key-pair.pem

# Change permissions of Key Pair
chmod 400 ~/.ssh/CSE3ACX-A2-key-pair.pem

# Create Security Group for public host
webAppSG=$(aws ec2 create-security-group --group-name webApp-sg --description "Security group for host in public subnet" --vpc-id "$VPC" --query 'GroupId' --output text)

# Create JSON file of resources to cleanup
resources=~/resources.json
OBJECT_NAME=testworkflow-2.0.1.jar
TARGET_LOCATION=/opt/test/testworkflow-2.0.1.jar

# Allow SSH and http traffic
aws ec2 authorize-security-group-ingress --group-id "$webAppSG" --protocol tcp --port 22 --cidr 0.0.0.0/0 --query 'Return' --output text
aws ec2 authorize-security-group-ingress --group-id "$webAppSG" --protocol tcp --port 80 --cidr 0.0.0.0/0 --query 'Return' --output text



##############   TASK 2 #################

# Create EC2 Instance
ec2ID=$(aws ec2 run-instances --image-id ami-0b0dcb5067f052a63 --count 1 --instance-type t2.micro --key-name CSE3ACX-A2-key-pair --security-group-ids "$webAppSG" --subnet-id "$subnet0" --user-data file://CSE3ACX-A2-user-data.txt --query Instances[].InstanceId --output text)

# Allocate an Elastic IP address
pubIP=$(aws ec2 allocate-address --query 'PublicIp' --output text)

# Determine allocation IP
eipalloc=$( aws ec2 describe-addresses --query "Addresses[?PublicIp == $pubIP].AllocationId" --output text )

# Associate IP address with EC2 instance (needs to be in the running state)
ec2status=$( aws ec2 describe-instances --instance-ids $ec2ID --query 'Reservations[].Instances[].State.Name' --output text  )

while [ $ec2status != "running" ]
do
  echo Status: $ec2status trying again in 10 seconds
  ec2status=$( aws ec2 describe-instances --instance-ids $ec2ID --query 'Reservations[].Instances[].State.Name' --output text  )
  sleep 10
done

ipAssociation=$(aws ec2 associate-address --instance-id $ec2ID --public-ip $pubIP --output text)

# Create json file of resources
JSON_STRING=$( jq -n \
                  --arg vpcID "$VPC" \
                  --arg sn0 "$subnet0" \
                  --arg rtb "$PubRouteTable" \
                  --arg igw "$internetGateway" \
                  --arg sg "$webAppSG" \
                  --arg ec2 "$ec2ID" \
                  --arg eipalloc "$eipalloc" \
                  '{"VPC-ID": $vpcID, Subnet0: $sn0, PubRouteTable: $rtb, internetGateway: $igw, webAppSG: $sg, ec2ID: $ec2, eipalloc: $eipalloc}' )

echo $JSON_STRING > $resources

#  End of script status
greenText='\033[0;32m'
NC='\033[0m' # No Color
echo "Connect to CLI using the command below"
echo -e "\n${greenText}\t\t ssh -i ~/.ssh/CSE3ACX-A2-key-pair.pem ec2-user@$pubIP ${NC}\n"
echo "Connect to the website below"
echo -e "\n${greenText}\t\t http://$pubIP ${NC}\n"
