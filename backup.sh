#!/bin/bash
#################################################################
# You need megatools in order to upload your backup file to MEGA
# Download megatools from http://megatools.megous.com/
#################################################################
# Simple backup script for GNU/Linux servers
# Main features:
#	- Backup custom files and directories
#	- Backup MySQL/PostgreSQL databases
#	- Copy/SCP/FTP to another server or mounted media
#	- Upload to MEGA.nz cloud
#	- Send a notification to your email
#	- Logging all the activities
#
# Edit the configuration and run:
#	$ sudo bash backup.sh
#
# Please help to simplify and develop new features
# Narbeh - http://narbeh.org - narbeh@protonmail.com
#################################################################
## Reading a Remote/External URLBased confighuration 

bfn=backer.conf

if [  -e  "backer.conf"  ]
	then
	echo "\n :: ~>  Config file exist ~> starting the backup proccess \n "
else 
	echo -e "\n         [  Config File Doesn't Exist  ] \n"
    read -p "Enter External Configuration URL: " EXT_URL
 
   
    curl -o ${bfn} ${EXT_URL} 
fi 
################
#source ${bfn}
# Configuration
################
sleep 5



# Server Name
server_name=`grep "^server_name=" ${bfn} | cut -d= -f2`

# Backup path
backup_path=`grep "^backup_path=" ${bfn} | cut -d= -f2`

# Script log file
log_file=`grep "^log_file=" ${bfn} | cut -d= -f2`

# Files to backup (Multi value)
backup_files_enable=`grep "^backup_files_enable=" ${bfn} | cut -d= -f2`
backup_files="/root/.bash_history /etc/passwd"

# Directories to backup (Multi value)
backup_dir_enable=`grep "^backup_dir_enable=" ${bfn} | cut -d= -f2`
backup_directories=`grep "^backup_directories=" ${bfn}  | cut -d= -f2`

# Copy to other media (Multi value)
external_copy=`grep "^external_copy=" ${bfn}  | cut -d= -f2`
external_storage=`grep "^external_storage=" ${bfn}  | cut -d= -f2`

# SCP to other server (Trusted servers for now)
scp_enable=`grep "^scp_enable=" ${bfn} | cut -d= -f2`
scp_server=`grep "^scp_server" ${bfn}  | cut -d= -f2`
scp_port=`grep "^scp_port" ${bfn}  | cut -d= -f2`
scp_username=`grep "^scp_username" ${bfn}  | cut -d= -f2`
scp_path=`grep "^scp_path=" ${bfn} | cut -d= -f2`

# Enable iptables backup
iptables_backup=`grep "^iptables_backup" ${bfn} | cut -d= -f2`

# Upload to FTP server (Using curl command)
ftp_enable=`grep "^ftp_enable=" ${bfn}  | cut -d= -f2`
ftp_server=`grep "^ftp_server=" ${bfn}  | cut -d= -f2`
ftp_path=`grep "^ftp_path=" ${bfn}  | cut -d= -f2`
ftp_username=`grep "^ftp_username=" ${bfn}  | cut -d= -f2`
ftp_password=`grep "^ftp_password=" ${bfn}  | cut -d= -f2`

# Send an email the result of the backup process
# You should have sendmail or postfix installed
send_email=`grep "^send_email=" ${bfn}  | cut -d= -f2`
email_to=`grep "^email_to=" ${bfn}  | cut -d= -f2`

# Upload to MEGA.nz if you have installed the client.
# /Root/ is the main directory in MEGA.nz
mega_enable=`grep "^mega_enable=" ${bfn}  | cut -d= -f2`
mega_email=`grep "^mega_email=" ${bfn}  | cut -d= -f2`
mega_pass=`grep "^mega_pass=" ${bfn}  | cut -d= -f2`
mega_path=`grep "^mega_path=" ${bfn}  | cut -d= -f2`  #

# Full MySQL dump (All Databases)
mysql_backup=`grep "^mysql_backup=" ${bfn}  | cut -d= -f2`
mysql_user=`grep "^mysql_user=" ${bfn}  | cut -d= -f2`
mysql_pass=`grep "^mysql_pass=" ${bfn}  | cut -d= -f2`

# Full PostgreSQL dump (All Databases)
postgres_backup=`grep "^postgres_backup=" ${bfn}  | cut -d= -f2`
postgres_user=`grep "^postgres_user=" ${bfn}  | cut -d= -f2`
postgres_pass=`grep "^postgres_pass=" ${bfn}  | cut -d= -f2`
postgres_database=`grep "^postgres_database=" ${bfn}  | cut -d= -f2`
postgres_host=`grep "^postgres_host=" ${bfn}  | cut -d= -f2`
postgres_port=`grep "^postgres_port=" ${bfn}  | cut -d= -f2`

################################################################
################################################################
################################################################

###############
#Do the backup
###############



case $1 in
	"--fresh" )
		rm /var/backup_lock 2> /dev/null;;
	*)
		:;;
esac

# Main variables
color='\033[0;36m'
color_fail='\033[0;31m'
nc='\033[0m'
hostname=$(hostname -s)
date_now=$(date +"%Y-%m-%d %H:%M:%S")





# Checking lock file
test -r /var/backup_lock
if [ $? -eq 0 ];then
	echo -e "\n ${color}--- $date_now There is another backup process. \n${nc}"
	echo "$date_now There is another backup process." >> $log_file
	echo -e "\n ${color}--- $date_now If not, run the script with --fresh argument. \n${nc}"
	exit
fi

touch /var/backup_lock 2> /dev/null
path_date=$(hostname -s)_$(date +"%Y-%m-%d-%H-%M-%S")
mkdir -p $backup_path/Backup/$path_date 2>> $log_file
echo -e "\n ${color}--- $date_now Backup started. \n${nc}"
echo "$date_now Backup started." >> $log_file

sleep 1






# Backing up the files
if [ $backup_files_enable = "yes" ]
then
	echo -e "\n ${color}--- $date_now Backing up files \n${nc}"
	echo "$date_now Backing up files" >> $log_file
	mkdir $backup_path/Backup/$path_date/custom_files | tee -a $log_file
	for backup_custom_files in $backup_files
	do
		echo "--> $backup_custom_files" | tee -a $log_file
		cp $backup_files $backup_path/Backup/$path_date/custom_files/ 2>> $log_file
	done
	echo
fi

if [ $iptables_backup = "yes" ]
then
        echo -e "\n ${color}--- $date_now Backing up iptables rules \n${nc}"
        echo "$date_now Backing up iptables rules" >> $log_file
	iptables-save >> $backup_path/Backup/$path_date/custom_files/iptables-save
        echo
fi

sleep 1





# Backing up the directories
if [ $backup_dir_enable = "yes" ]
then
	echo -e "\n ${color}--- $date_now Backing up directories \n${nc}"
	echo "$date_now Backing up directories" >> $log_file
	for backup_dirs in $backup_directories
	do
		echo "--> $backup_dirs" | tee -a $log_file
		dir_name=`echo $backup_dirs | cut -d / -f2- | sed 's/\//-/g'`
		tar -cjf $backup_path/Backup/$path_date/$dir_name.tar.bz2 $backup_dirs/ > /dev/null 2> /dev/null
	done
	echo
fi

sleep 1




# MySQL backup
if [ $mysql_backup = "yes" ]
then
	echo -e "\n ${color}--- $date_now MySQL backup enabled, backing up: \n${nc}"
	echo "$date_now MySQL backup enabled, backing up" >> $log_file
	# Using ionice for MySQL dump
	ionice -c 3 mysqldump -u $mysql_user -p$mysql_pass --events --all-databases | gzip -9 > $backup_path/Backup/$path_date/MySQL_Full_Dump_$path_date.sql.gz | tee -a $log_file
	if [ $? -eq 0 ]
	then
		echo -e "\n ${color}--- $date_now MySQL backup completed. \n${nc}"
		echo "$date_now Backing up files" >> $log_file
	fi
fi

sleep 1






# PostgreSQL backup
if [ $postgres_backup = "yes" ]
then
	# Creating ~/.pgpass for PostgreSQL password
	# PostgreSQL does not support inline password
	# Know better solution? Let me know.
	USERNAME=`whoami`
	if [ $USERNAME = "root" ]
	then
		cp /root/.pgpass /root/.pgpass_BACKUP_$(date +"%Y-%m-%d-%H-%M-%S") > /dev/null 2> /dev/null
		echo "$postgres_host:$postgres_port:$postgres_database:$postgres_user:$postgres_pass" > /root/.pgpass
		chmod 600 /root/.pgpass
	else
		cp /home/$USERNAME/.pgpass /home/$USERNAME/.pgpass_BACKUP_$(date +"%Y-%m-%d-%H-%M-%S") > /dev/null 2> /dev/null
		echo "$postgres_host:$postgres_port:$postgres_database:$postgres_user:$postgres_pass" > /home/$USERNAME/.pgpass
		chmod 600 /home/$USERNAME/.pgpass
	fi

	echo -e "\n ${color}--- $date_now PostgreSQL backup enabled, backing up: \n${nc}"
	echo "$date_now PostgreSQL backup enabled, backing up" >> $log_file
	# Using ionice for PostgreSQL dump
	ionice -c 3 pg_dump -p $postgres_port -h $postgres_host -Fc -U $postgres_user $postgres_database > $backup_path/Backup/$path_date/Postgres_Full_Dump_$path_date.dump | tee -a $log_file
	if [ $? -eq 0 ]
	then
		echo -e "\n ${color}--- $date_now PostgreSQL backup completed. \n${nc}"
		echo "$date_now PostgreSQL backup completed" >> $log_file
	fi
fi

sleep 1




############################################################################################

# Create TAR file
echo -e "\n ${color}--- $date_now Creating TAR file located in $backup_path/Full_Backup_$path_date.tar.bz2 \n${nc}"
echo "$date_now Creating TAR file located in $backup_path/Full_Backup_$path_date.tar.bz2" >> $log_file
tar -cjf $backup_path/Full_Backup_${path_date}.tar.bz2 $backup_path/Backup/$path_date 2> /dev/null
rm -rf $backup_path/Backup/

sleep 1

############################################################################################



# Copy to other storage
if [ $external_copy = "yes" ]
then
	for cp_paths in $external_storage
	do
		echo -e "\n ${color}--- $date_now Copy backup archive to $cp_paths: \n${nc}"
		echo "$date_now Copy backup archive to $cp_paths" >> $log_file
		cp $backup_path/Full_Backup_$path_date.tar.bz2 $cp_paths/
		if [ $? -eq 0 ]
		then
			echo -e "Copied to $cp_paths. \n"
			echo "$date_now Copied to $cp_paths" >> $log_file
		else
			echo -e " ${color_fail} Copy to $cp_paths failed. ${nc} \n"
			echo "$date_now Copy to $cp_paths failed. Please investigate." >> $log_file
		fi
	done
fi

sleep 1






# SCP to other server
if [ $scp_enable = "yes" ]
then
	echo -e "\n ${color}--- $date_now SCP backup archive to $scp_server: \n${nc}"
	echo "$date_now SCP backup archive to $scp_server" >> $log_file
	scp -P $scp_port $backup_path/Full_Backup_$path_date.tar.bz2 '$scp_username'@'$scp_server':$scp_path
	echo "$date_now SCP done" | tee -a $log_file
fi

sleep 1






# Upload to FTP server
if [ $ftp_enable = "yes" ]
then
	if [ `which curl` ]
	then
		echo -e "\n ${color}--- $date_now Uploading backup archive to FTP server $ftp_server \n${nc}"
		echo "$date_now Uploading backup archive to FTP server $ftp_server" >> $log_file
		curl --connect-timeout 30 -S -T $backup_path/Full_Backup_$path_date.tar.bz2 ftp://$ftp_server/$ftp_path --user $ftp_username:$ftp_password | tee -a $log_file
		if [ $? -eq 0 ]
		then
			echo "$date_now FTP Upload Done" | tee -a $log_file
		else
			echo -e "\n ${color_fail}--- $date_now FTP upload failed. \n${nc}"
			echo "$date_now FTP upload failed. Please investigate." >> $log_file
		fi
	else
		echo -e " ${color_fail}--- $date_now You have been enabled FTP upload. ${nc}"
		echo -e " ${color_fail}--- $date_now You need to install curl package. ${nc}"
		echo -e " ${color_fail}--- $date_now FTP upload failed. ${nc}"
		echo "$date_now FTP upload failed. Install 'curl' package." >> $log_file
	fi
fi





# Upload TAR file to MEGA.nz
if [ $mega_enable = "yes" ]
then
	if [ `which megaput` ]
	then
		echo -e "\n ${color}--- $date_now Uploading backup archive to MEGA.nz \n${nc}"
		echo "$date_now Uploading backup archive to MEGA.nz" >> $log_file
		megaput --reload --path $mega_path -u $mega_email -p $mega_pass $backup_path/Full_Backup_$path_date.tar.bz2
		echo "$date_now MEGA Upload Done. Path: $mega_path" | tee -a $log_file
	else
		echo -e " ${color_fail}--- $date_now You have been enabled MEGA upload. ${nc}"
		echo -e " ${color_fail}--- $date_now You need to install megatools from http://megatools.megous.com ${nc}"
		echo -e " ${color_fail}--- $date_now MEGA upload failed. ${nc}"
		echo "$date_now Uploading to MEGA.nz failed. Install 'megatools' from http://megatools.megous.com" >> $log_file
	fi
fi





# Send a simple email notification
if [ $send_email = "yes" ]
then
	echo -e "Backup completed $date_now\nBackup path: $backup_path/Full_Backup_$path_date.tar.bz2" | mail -s "Backup Result" $email_to >> $log_file 2>&1
fi

echo -e "\n"
echo -e "###########################################################"
echo -e "$date_now Backup finished"
echo -e "Backup path: $backup_path/Full_Backup_${server_name}_${hostname}_${path_date}.tar.bz2"
echo -e "###########################################################"
echo -e "\n"
echo "$date_now Backup finished. Backup path: $backup_path/Full_Backup_${path_date}.tar.bz" >> $log_file
echo "#######################" >> $log_file



# Removing lock after successful backup
rm /var/backup_lock

exit 0
