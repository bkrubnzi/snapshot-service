#!/bin/bash

#INSTANCES=`/home/ec2-user/show-running-instances.sh | awk '{print $2}' | perl -pe 's/\n/,/g'`;INSTANCES=${INSTANCES:0:`expr length $INSTANCES`-1}
INSTANCES="i-3ba7545a,i-87a226e9,i-b2cd9bd5,i-077aea6c9102951c0,i-03799445dbdd495b1,i-1c03b00a"
VOLUMES=`aws ec2 describe-volumes --filters Name="attachment.instance-id",Values="$INSTANCES" --query "Volumes[*].[VolumeId]" --output text`

TODAY_NUM=`date | awk '{print $3}'`
TODAY_DAY=`date | awk '{print $1}'`

LOG_FILENAME="/home/ec2-user/log/created_snapshots.log"
MESSAGE=$(date "+%Y-%m-%d_%H:%M:%S")": Beginning Execution"
echo "----" >> $LOG_FILENAME
echo $MESSAGE >> $LOG_FILENAME

while IFS= read -r volume;do 
	if ( [ $TODAY_NUM -ne "1" ] && [ $TODAY_DAY != "Sun" ] ); then
		echo "Taking a daily snapshot of $volume..." &>> $LOG_FILENAME
		aws ec2 create-snapshot --volume-id $volume --description "Daily automated snapshot. Please delete if older than 7 days." --output text 2>&1 | grep -v -e '^[[:space:]]*$' &>> $LOG_FILENAME
	elif [ $TODAY_NUM -eq "1" ];then
		echo "Taking a monthly snapshot of $volume..." &>> $LOG_FILENAME
		aws ec2 create-snapshot --volume-id $volume --description "Monthly automated snapshot. Please delete if older than 3 months." --output text 2>&1 | grep -v -e '^[[:space:]]*$' &>> $LOG_FILENAME
	else
		echo "Taking a weekly snapshot of $volume..." &>> $LOG_FILENAME
		aws ec2 create-snapshot --volume-id $volume --description "Weekly automated snapshot. Please delete if older than 8 weeks." --output text 2>&1 | grep -v -e '^[[:space:]]*$' &>> $LOG_FILENAME
	fi
done <<< "$VOLUMES"

MESSAGE=$(date "+%Y-%m-%d_%H:%M:%S")": Completed Execution"
echo $MESSAGE >> $LOG_FILENAME
