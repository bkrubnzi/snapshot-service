#!/bin/bash

SEVEN_DAYS_AGO=$(date --date '7 days ago' +%s)
EIGHT_WEEKS_AGO=$(date --date '8 weeks ago' +%s)
THREE_MONTHS_AGO=$(date --date '3 months ago' +%s)
TWELVE_MONTHS_AGO=$(date --date '12 months ago' +%s)


ACCOUNT_NUMBER=`aws ec2 describe-security-groups --query 'SecurityGroups[0].IpPermissions[0].UserIdGroupPairs[0].UserId' --output text`
if [ $ACCOUNT_NUMBER == "None" ];then
	ACCOUNT_NUMBER=`aws ec2 describe-security-groups --query 'SecurityGroups[0].OwnerId' --output text`
fi

DAILIES=`aws ec2 describe-snapshots --owner-id $ACCOUNT_NUMBER --filters Name="description",Values="Daily*" --query Snapshots[*].[StartTime,SnapshotId] --output text`
WEEKLIES=`aws ec2 describe-snapshots --owner-id $ACCOUNT_NUMBER --filters Name="description",Values="Weekly*" --query Snapshots[*].[StartTime,SnapshotId] --output text`
MONTHLIES=`aws ec2 describe-snapshots --owner-id $ACCOUNT_NUMBER --filters Name="description",Values="Monthly*" --query Snapshots[*].[StartTime,SnapshotId] --output text`
ALL_SNAPSHOTS=`aws ec2 describe-snapshots --owner-id $ACCOUNT_NUMBER --query Snapshots[*].[StartTime,SnapshotId] --output text`

LOG_FILENAME="/home/ec2-user/log/deleted_snapshots.log"
MESSAGE=$(date "+%Y-%m-%d_%H:%M:%S")": Beginning Execution"
echo "----" >> $LOG_FILENAME
echo $MESSAGE >> $LOG_FILENAME


if [ "$DAILIES" ];then
	while IFS= read -r snap_data;do
		snap_date=$(echo $snap_data | cut -f1 -d' ')
		stamp=$(date --date $snap_date +%s)
		if [ $stamp -le $SEVEN_DAYS_AGO ];then
			snap_id=$(echo $snap_data | cut -f2 -d' ')
			echo "Deleting daily snapshot:"$snap_date","$stamp","$snap_id &>> $LOG_FILENAME 
			aws ec2 delete-snapshot --snapshot-id $snap_id 2>&1 | grep -v -e '^[[:space:]]*$' &>> $LOG_FILENAME
		fi
	done <<< "$DAILIES"
fi

if [ "$WEEKLIES" ];then
	while IFS= read -r snap_data;do
		snap_date=$(echo $snap_data | cut -f1 -d' ')
		stamp=$(date --date $snap_date +%s)
		if [ $stamp -le $EIGHT_WEEKS_AGO ];then
			snap_id=$(echo $snap_data | cut -f2 -d' ')
			echo "Deleting weekly snapshot:"$snap_date","$stamp","$snap_id &>> $LOG_FILENAME
			aws ec2 delete-snapshot --snapshot-id $snap_id 2>&1 | grep -v -e '^[[:space:]]*$' &>> $LOG_FILENAME
		fi
	done <<< "$WEEKLIES"
fi

if [ "$MONTHLIES" ];then
	while IFS= read -r snap_data;do
		snap_date=$(echo $snap_data | cut -f1 -d' ')
		stamp=$(date --date $snap_date +%s)
		if [ $stamp -le $THREE_MONTHS_AGO ];then
			snap_id=$(echo $snap_data | cut -f2 -d' ')
			echo "Deleting monthly snapshot:"$snap_date","$stamp","$snap_id &>> $LOG_FILENAME
			aws ec2 delete-snapshot --snapshot-id $snap_id 2>&1 | grep -v -e '^[[:space:]]*$' &>> $LOG_FILENAME
		fi
	done <<< "$MONTHLIES"
fi

if [ "$ALL_SNAPSHOTS" ];then
	while IFS= read -r snap_data;do
		snap_date=$(echo $snap_data | cut -f1 -d' ')
		stamp=$(date --date $snap_date +%s)
		if [ $stamp -le $TWELVE_MONTHS_AGO ];then
			snap_id=$(echo $snap_data | cut -f2 -d' ')
			echo "Deleting expired snapshot:"$snap_date","$stamp","$snap_id &>> $LOG_FILENAME
			aws ec2 delete-snapshot --snapshot-id $snap_id 2>&1 | grep -v -e '^[[:space:]]*$' &>> $LOG_FILENAME
		fi
	done <<< "$ALL_SNAPSHOTS"
fi

MESSAGE=$(date "+%Y-%m-%d_%H:%M:%S")": Completed Execution"
echo $MESSAGE >> $LOG_FILENAME
