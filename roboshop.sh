#!/bin/bash
AMI_ID="ami-09c813fb71547fc4f"
SG_ID="sg-02f8a8f87c9497fcd"
INSTANCES=("mongodb" "redis" "mysql" "rabbitmq" "catalogue" "user" "cart" "shipping" "payment" 
"dispatch" "frontend")
ZONE_ID="Z0559090BH4WWPB2ISUM"
DOMAIN_NAME="monnish.com"

for instance in ${INSTANCES[@]}
do
   
    INSTANCE_ID=$(aws ec2 run-instances --image-id ami-09c813fb71547fc4f \
     --instance-type t2.micro \
     --security-group-ids sg-02f8a8f87c9497fcd \
     --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" \
     --query "Instances[0].InstanceId" --output text)
    
    if [ $instance != "frontend" ]
    then 
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
        --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
    else
        IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
        --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    fi
    echo  "$instance IP ADDRESS : $ip"

    ws route53 change-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --change-batch '
  {
    "Comment": "Testing creating a record set"
    ,"Changes": [{
      "Action"              : "CREATE"
      ,"ResourceRecordSet"  : {
        "Name"              : "'$instance'.'$DOMAIN_NAME'"
        ,"Type"             : "A"
        ,"TTL"              : 1
        ,"ResourceRecords"  : [{
            "Value"         : "' $IP'"
        }]
      }
    }]
  }'

    

done