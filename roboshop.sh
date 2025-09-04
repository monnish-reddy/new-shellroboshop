#!/bin/bash
AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-02f8a8f87c9497fcd"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" "dispatch" "frontend")
ZONE_ID="Z0559090BH4WWPB2ISUM"
DOMAIN_NAME="monnish.com"

for instance in ${INSTANCES[@]}
do
    if [ "$instance" == "frontend" ]; then
        INSTANCE_ID=$(aws ec2 run-instances \
            --image-id $AMI_ID \
            --instance-type t2.micro \
            --security-group-ids $SG_ID \
            --associate-public-ip-address \
            --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
            --query "Instances[0].InstanceId" --output text)
    else
        INSTANCE_ID=$(aws ec2 run-instances \
            --image-id $AMI_ID \
            --instance-type t2.micro \
            --security-group-ids $SG_ID \
            --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
            --query "Instances[0].InstanceId" --output text)
    fi

    # Wait until instance is running
    aws ec2 wait instance-running --instance-ids $INSTANCE_ID

    # Fetch IP (Public for frontend, Private for others)
    if [ "$instance" == "frontend" ]; then
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
            --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
            --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
    fi

    echo "$instance IP ADDRESS : $IP"

    # Update Route53 DNS
    aws route53 change-resource-record-sets \
      --hosted-zone-id $ZONE_ID \
      --change-batch "{
        \"Comment\": \"Add DNS record for $instance\",
        \"Changes\": [{
          \"Action\": \"UPSERT\",
          \"ResourceRecordSet\": {
            \"Name\": \"$instance.$DOMAIN_NAME\",
            \"Type\": \"A\",
            \"TTL\": 60,
            \"ResourceRecords\": [{\"Value\": \"$IP\"}]
          }
        }]
      }"
done
