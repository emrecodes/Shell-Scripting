#!/bin/bash
HOST=hostAddress
PORT=portNo
USER=userName
PASSWORD=password

#Makes the extension of all xyz files in SourceFolder abc
for x in /SourceFolder/*.xyz; do mv "$x" "${x%.xyz}.abc"; done

SOURCE_FILE=/SourceFolder/*.abc
TARGET_DIR=/TargetFolder/tmp

#Use expect to automatically send all abc files to targer folder with sftp
/usr/bin/expect<<EOD

spawn /usr/bin/sftp -o Port=$PORT $USER@$HOST
expect "password:"
send "$PASSWORD\r"
expect "sftp>"
send "put $SOURCE_FILE $TARGET_DIR\r"
expect "sftp>"
send "bye\r"
EOD


###  Rename.sh => Add this script to crontab so files that have the extension changed to abc before sending will be xyz as in the original (Work at Sending Host)
###  !/bin/bash
###  for x in /SourceFolder/*.abc; do mv "$x" "${x%.abc}.xyz"; done

###  Rename2.sh => Add this script to crontab so files that have sent as abc will display as their original extension xyz (Work at Receiving Host)
###  #!/bin/bash
###  for x in /TargetFolder/tmp/*.abc; do mv "$x" "${x%.abc}.xyz"; done

##################  THE FLOW HERE IS AS FOLLOWS:  ##################
## The first host wants to send files with the extension xyz to the second server, and the third server will periodically pull these files from the second server. ##
## But sometimes there are xyz files being sent from the first to the second while the third server is pulling the file. ##
## In this case, the third server can receive some xyz files in half. ##
## To avoid this, you need to change the extension. When entering 3 scripts here in crontab, their timing should be adjusted accordingly. ##
