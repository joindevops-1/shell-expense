#!/bin/bash

USERID=$(id -u)
TIMESTAMP=$(date "+%Y-%m-%d-%H-%M-%S")
SCRIPTNAME=$(echo $0 | cut -d "." -f1)
LOGS_FOLDER="/var/log/expense"
mkdir -p $LOGS_FOLDER
LOGFILE="$LOGS_FOLDER/$SCRIPTNAME-$TIMESTAMP.log"
R="\e[31m"
G="\e[32m"
N="\e[0m"

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo "$R Please run this script with root priveleges $N" | tee -a $LOGFILE
        exit 1
    fi
}

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is...$R FAILED $N" | tee -a $LOGFILE
        exit 1
    else
        echo -e "$2 is... $G SUCCESS $N" | tee -a $LOGFILE
    fi
}

echo "script started executing at: $(date)" | tee -a $LOGFILE
CHECK_ROOT

dnf install nginx -y &>>$LOGFILE
VALIDATE $? "Installing nginx"

systemctl enable nginx &>>$LOGFILE
VALIDATE $? "Enabling nginx"

systemctl start nginx &>>$LOGFILE
VALIDATE $? "Starting nginx"

rm -rf /usr/share/nginx/html/* &>>$LOGFILE
VALIDATE $? "Removing existing content"

curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip &>>$LOGFILE
VALIDATE $? "Downloading frontend code"

cd /usr/share/nginx/html &>>$LOGFILE
unzip /tmp/frontend.zip &>>$LOGFILE
VALIDATE $? "Extracting frontend code"

#check your repo and path
cp /home/ec2-user/shell-expense/expense.conf /etc/nginx/default.d/expense.conf &>>$LOGFILE
VALIDATE $? "Copied expense conf"

systemctl restart nginx &>>$LOGFILE
VALIDATE $? "Restarting nginx"