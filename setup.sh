#!/bin/bash
#Script for Backup
#Written by Robin Chhetri
PATH=/usr/bin:/bin
PDIR={0%`basename $0`}
BZ2_FILENAME=backup.tar.bz2
TMP_DIR=/tmp/$(basename $0).$$.tmp
MED_DIR=/media
FILE1=backupdg.sh
FILE2=script.sh
PROPER_FILE=directory.properties
USER=test12
PASSWORD=test12
SERVER=192.168.0.1
modify_cron()
{
	sed -i '/backupdg.sh/d' $MED_DIR/mycron
	echo "Modifying Cron Entry."
	echo "Enter Time in Hours(0-23)"
	read hour
	if [[ $hour != [0-9]* ]]; then
	echo "Non valid integer entered. Zero assumed."
	hour=0 
	fi
	echo "Enter Time in Minutes (0-60):"
	read minutes 
	if [[ $minutes != [0-9]* ]]; then	
        echo "Non valid integer entered. Zero assumed."
        minutes=0
        fi
	echo "Assuming daily cron job except on Sundays, this entry will be added to crontab"
	echo "$minutes $hour * * 1-6 /bin/bash /media/backupdg.sh"
	echo "Press Y to accept."
	read tmp_val
	 if [[ $tmp_val == "Y" || $tmp_dir == "y" ]]; then
                echo "$minutes $hour * * 1-6 /bin/bash /media/backupdg.sh" >> $MED_DIR/mycron
		sed -i '/^$/d' $MED_DIR/mycron
	 else 
		modify_cron
    	 fi

	

}



trap 'rm -f ${PDIR}/${BZ2_FILENAME}; exit 1' HUP INT QUIT TERM
if [ -d "$TMP_DIR" ]; then
	rm -rf $TMP_DIR
fi
if [ -f "`pwd`/$BZ2_FILENAME" ]; then
	rm -f $BZ2_FILENAME
fi
echo "Downloading files from FTP server..."
wget "ftp://$USER:$PASSWORD@$SERVER/BackupScript/backup.tar.bz2"
echo "Unpacking files.."
tar -xvjf $PWD/backup.tar.bz2 
mv $PWD/BackupScript $TMP_DIR
echo "Moving files to /media..."
if [ -f "${MED_DIR}/${FILE1}" ]; then
	 rm -f /media/backupdg.sh /media/script.sh
fi
mv $TMP_DIR/$FILE1 $MED_DIR
mv $TMP_DIR/$FILE2 $MED_DIR
echo "creating mount direcotry"

if [ ! -d "$MED_DIR/smb" ]; then
     mkdir $MED_DIR/smb
fi

if [ ! -f "$MED_DIR/$PROPER_FILE" ]; then
echo "No properties file exists! I am going to create one."
echo "Type a directory that you want to backup. Press N to finish."
while read tmp_dir; do
	if [[ $tmp_dir == "n" || $tmp_dir == "N" ]]; then
		break;
	fi 
	if [ ! -d "$tmp_dir" ]; then
		echo "Directory $tmp_dir does not exist. Please try again."
	else 
		echo "Adding $tmp_dir to properties file."
		echo $tmp_dir >> $MED_DIR/$PROPER_FILE
	fi
done
else
echo "Properties file exists! Do you want to modify the properties file? n/Y"
read ans
if [[ $ans == "Y" || $ans == "y" ]]; then
	echo "Redoing Properties file. Current Properties file has the following directories."
	cat $MED_DIR/$PROPER_FILE | awk '{ print $0}'  
	echo "Do you want to modify the directory list? n/Y"
	read answ2
	if [[ $answ2 == "Y" || $answ2 == "y" ]]; then
		rm -f $MED_DIR/$PROPER_FILE
		echo "Recreationg properties file."
		echo "Type a directory that you want to backup. Press N to finish."
		while read tmp_dir; do
        if [[ $tmp_dir == "n" || $tmp_dir == "N" ]]; then
                break;
        fi
        if [ ! -d "$tmp_dir" ]; then
                echo "Directory $tmp_dir does not exist. Please try again."
        else
                echo "Adding $tmp_dir to properties file."
                echo $tmp_dir >> $MED_DIR/$PROPER_FILE
        fi
done

	fi
fi
fi
echo "Reading cron entries to see if crontab is set up..."
crontab -l > $MED_DIR/mycron
grep -q  $FILE1 $MED_DIR/mycron
if [[ $? -eq 0 ]] ;
then
echo "Cron entry already exists". 
echo "Here is the cron entry:"
grep $FILE1 $MED_DIR/mycron
echo "Do you want to modify the cron entry? n/Y"
read tmp_val
 if [[ $tmp_val == "Y" || $tmp_dir == "y" ]]; then
                modify_cron
		crontab $MED_DIR/mycron
  fi
else
	echo "Cron entry do not exist."
	modify_cron
	crontab $MED_DIR/mycron
fi
rm -f $MED_DIR/mycron
echo "Creating necessary log files"
touch $MED_DIR/cerror.log
touch $MED_DIR/logfile.log
touch $MED_DIR/error.log
echo "System setup complete."
