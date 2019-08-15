#!/bin/bash
###########################################
# @Author: Sriharsha Gangam
# email: Sriharsha_Gangam@comcast.com
###########################################

echo "Usage: loopDays.sh --state_dir <STATE_ROOT_DIR> --look_back <NDAYS> --offset <OFFSET_DAYS> --job_name <JOB_NAME> --max_attempts <ALERT_THRESHOLD> --alert_email <ALERT_DESTINATION_EMAIL_ADDRESS> --mail_server <MAIL_SERVER_FOR_ALERT>  --sleep_seconds <SLEEP_SECONDS> <myjob.sh> <myJobArguments>"

if [ $# -lt 17 ]; then
  echo "Illegal number of parameters"
  exit 1
fi

for arg in "$@"; do
	shift
	case "$arg" in
		"--state_dir")          set -- "$@" "-s" ;;
		"--look_back") 		set -- "$@" "-n" ;;
		"--offset") 		set -- "$@" "-o" ;;
		"--job_name") 		set -- "$@" "-j" ;;
		"--max_attempts") 	set -- "$@" "-a" ;;
		"--alert_email") 	set -- "$@" "-e" ;;
		"--mail_server") 	set -- "$@" "-m" ;;
		"--sleep_seconds") 	set -- "$@" "-l" ;;
		*) 			set -- "$@" "$arg"
	esac
done

while getopts ":s:n:o:j:a:e:m:l:" opt; do
        case $opt in
                s)
                        STATE_ROOT_DIR=$OPTARG
                        echo "STATE_ROOT_DIR = $STATE_ROOT_DIR"
                        ;;
                n)
                        NDAYS=$OPTARG
                        echo "NDAYS = $NDAYS"
                        ;;
                o)
                        OFFSET_DAYS=$OPTARG
                        echo "OFFSET_DAYS = $OFFSET_DAYS"
                        ;;
                j)
                        JOB_NAME=$OPTARG
                        echo "JOB_NAME = $JOB_NAME"
                        ;;
                a)
                        ALERT_THRESHOLD=$OPTARG
                        echo "ALERT_THRESHOLD = $ALERT_THRESHOLD"
                        ;;
                e)
                        ALERT_EMAIL_ADDRESS=$OPTARG
                        echo "ALERT_EMAIL_ADDRESS = $ALERT_EMAIL_ADDRESS"
                        ;;
                m)
                        ALERT_MAIL_SERVER=$OPTARG
                        echo "ALERT_MAIL_SERVER = $ALERT_MAIL_SERVER"
                        ;;
                l)
                        SLEEP_SECONDS=$OPTARG
                        echo "SLEEP_SECONDS = $SLEEP_SECONDS"
                        ;;
		*)
			;;
        esac
done


shift $((OPTIND - 1))

function alert_multple_failures {
   JOB_NAME=$1
   DATE=$2
   ATTEMPTS=$3
   FROM_EMAIL="loopdays@$(hostname)"
   EMAIL_SERVER="$ALERT_MAIL_SERVER"
   USERS="$ALERT_EMAIL_ADDRESS"
   SUBJECT="Multiple failures for Job: $JOB_NAME for date:$DATE after $ATTEMPTS attempts"
   BODY="Alerting on multiple failures for Job: $JOB_NAME for date:$DATE after $ATTEMPTS attempts. Please contact Elements Team."
   echo "**************************************************"
   echo "$BODY" | mail -S smtp=smtp://$EMAIL_SERVER -s "$SUBJECT" "$USERS"
   echo $SUBJECT
   echo "Completed alerting"
} 

##### Get arguments for the job
COMMAND="$@"
TODAY=$(date +%Y%m%d)
NDAYS_AGO=$(date -d "$TODAY - ${NDAYS} day" +%Y%m%d)

##### Set start and end dates.
START_DATE=$(date -d "$NDAYS_AGO - ${OFFSET_DAYS} day" +%Y%m%d)
echo START_DATE: $START_DATE
END_DATE=$(date -d "$TODAY - ${OFFSET_DAYS} day" +%Y%m%d)
echo END_DATE: $END_DATE

##### Create necessary directories and files
JOB_STATUS_ROOT="${STATE_ROOT_DIR}/js_"${JOB_NAME}

##### Loop through the dates
curr_day=$START_DATE
while [ "$(date -d "$curr_day" +%Y%m%d)" -lt "$(date -d "$END_DATE" +%Y%m%d)" ]; do
  curr_day=$(date -d "$curr_day + 1 day" +%Y%m%d)
  JOB_STATUS_DAY="$JOB_STATUS_ROOT/$curr_day"
  mkdir -p $JOB_STATUS_DAY
  STARTED_FILE="$JOB_STATUS_DAY/STARTED"
  SUCCESS_FILE="$JOB_STATUS_DAY/SUCCESS"
  FAILED_FILE="$JOB_STATUS_DAY/FAILED"
  if [ -f $STARTED_FILE ]; then
    echo "Job $JOB_NAME for $curr_day has started but incomplete. Send Alert!"
  elif [ -f $SUCCESS_FILE ]; then
    echo "Job $JOB_NAME for $curr_day is Successful. Skipping day."
  else
    #The job has ether failed the prevous run or we are starting the job for the first time.
    attempt_no=1
    if [ -f $FAILED_FILE ]; then
       echo "Previous run for Job $JOB_NAME for $curr_day has Failed."
       prev_attempts=$(cat $FAILED_FILE)
       attempt_no=$(($prev_attempts + $attempt_no))
       mv $FAILED_FILE $STARTED_FILE
    fi
    run_day=$(date -d "$curr_day" +%Y-%m-%d)
    echo "Running command: $COMMAND $run_day"
    echo  $attempt_no > $STARTED_FILE
    bash $COMMAND $run_day
    error_code=$?
    echo "Return code for Job: $JOB_NAME Date: $curr_day is $error_code"
    #### Move to completed or failed based on the error code
    if [ $error_code -eq 0 ]; then
      mv $STARTED_FILE $SUCCESS_FILE
    else
      mv $STARTED_FILE $FAILED_FILE
      if [ "$attempt_no" -ge "$ALERT_THRESHOLD" ]; then
	 alert_multple_failures $JOB_NAME $curr_day $attempt_no
      fi
    fi
  fi
  echo ""
  sleep $SLEEP_SECONDS
done
