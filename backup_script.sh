#!/bin/bash
#Property of Dylan Porter
#For Drive Setup: https://stackoverflow.com/questions/33063673/bash-script-to-backup-data-to-google-drive

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

backup_Dir="LINUX_BACKUP"
zip_Name="LINUX_BACKUP.zip"
home_Dir="/home/dylan/"
timestamp="LINUX_BACKUP_DATESTAMP.txt"
time_interval=15

if [ ! -f $timestamp ]; then
	#Create Date Timestamp
	echo "`date`" > LINUX_BACKUP_DATESTAMP.txt
fi

#Extract Date Timestamp
date=$(head -1 LINUX_BACKUP_DATESTAMP.txt | awk '{print $4}')
prev_backup_hour=$(echo $date | awk -F ":" '{print $1}')
prev_backup_minute=$(echo $date | awk -F ":" '{print $2}')

current_hour=$(date +"%H")
current_minute=$(date +"%M")

#Calculates current time in minutes and subtracts from old time in minutes
total_elapsed_time=$(($(($((current_hour*60))+$current_minute))-$(($(($prev_backup_hour*60))+$prev_backup_minute))))

time_interval=$total_elapsed_time

#See if there are any changes on system before backing up

files=$(for eachFile in $(ls $home_Dir)
do
  if [ -f $eachFile ]; then
    echo $eachFile
  fi
done)

home_file_change_num=$(($(find $files -mmin -$time_interval | wc -l)-$(find LOG.txt LOG_DAILY.txt -mmin -$time_interval | wc -l)))
dir_change_num=$(find $(cat dirs_to_backup.txt) -mmin -$time_interval | wc -l)

if [[ $(($dir_change_num + $home_file_change_num)) -le 0 ]] && [[ ! "$1" == "daily" ]] ; then
  date
  echo "Nothing to Backup! Cancelling Job..."
  exit 1
fi

zenity --info --text="Google Drive Backup has Started" --title="Backup Started" --width=450

#Daily Job for CRONJOB
if [ "$1" == "daily" ]; then
  zip_Name="LINUX_BACKUP_DAILY.zip"
  backup_Dir="LINUX_BACKUP_DAILY"
fi

date # Display Date / time of backup

rm -r -f $backup_Dir
mkdir $backup_Dir 
mkdir $backup_Dir/Home_Directory

if [[ ! -e dirs_to_backup.txt ]]; then
    touch dirs_to_backup.txt
    echo "Please Enter Directories to Backup in dirs_to_backup.txt"
    exit 1
fi

dirsToBackup=$(cat dirs_to_backup.txt)
for eachDir in $dirsToBackup
do
  echo "Copying Directory: " $eachDir
  cp -r $eachDir $backup_Dir
done

for file in $files
do
  echo "Copying File: " $file
  cp $file $backup_Dir/Home_Directory
done

echo "Creating ZIP File of Backup"
zip -r $zip_Name $backup_Dir
echo "ZIP File Created"

echo "Removing Previous Backups"
removable_ids=$(drive list | grep $zip_Name | awk '{print $1}')
for eachID in $removable_ids
do
  drive delete --id $eachID
done

echo "Removed Previous Backups"

echo "Uploading to Google Drive..."
drive upload --file "$zip_Name"
echo "Uploaded to Google Drive"

rm -r -f $backup_Dir $zip_Name

echo "`date`" > LINUX_BACKUP_DATESTAMP.txt #Update the timestamp of successful upload

zenity --info --text="System Backup Finished. \nLocation: $backup_Dir \nFile: $zip_Name \n\nBackup has been Uploaded to Google Drive" --title="Backup Completed" --width=450


