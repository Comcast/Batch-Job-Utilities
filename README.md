# Loop Days
This repository contains a script targeted at daily jobs/processes to automatically track, and retry on failures.

## Background
Jobs that run daily typically have a date argument passed to it. For example, it could be a daily data extract job that uses the date to query datasets for one day duration. Such date parameters enables one to backfill the job executon of historical days and is a very common use case. Suppose we have a job/script that has the 'date' (format - %Y-%m-%d) as a last argument for the job. For such jobs it important to track the success and failures status, run backfills for the jobs, retry the jobs on failure and send alerts when necessary. This script acts as a wrapper to enable any kind of process that runs daily to track to achieve the above functions.

## Language
Bash


## Environment
Works on any linux environment.


## Usage
```

loopDays.sh --state_dir <STATE_ROOT_DIR> --look_back <NDAYS> --offset <OFFSET_DAYS> --job_name <JOB_NAME> --max_attempts <ALERT_THRESHOLD> --alert_email <ALERT_DESTINATION_EMAIL_ADDRESS> --mail_server <MAIL_SERVER_FOR_ALERT>  --sleep_seconds <SLEEP_SECONDS> <myjob.sh> <myJobArguments>

Arguments:

"--state_dir": Directory location where the daily job status is stored.
"--look_back": Number of days to loop back.
"--offset": The job offset from the current date.
"--job_name": Name of the job.
"--max_attempts": Max number of attempts for a given date before an alert email is sent.
"--alert_email": Destination email addresses to receive alerts.
"--mail_server": Mailserver to send the email alert.
"--sleep_seconds": The number of seconds to sleep between each run of a day. Mainly used for back-pressure purposes.

```

## Example

Suppose we have an unreliable job that runs daily but does not succeed all the time.


```
Suppose we normally run a job as follows. Please note that date is the last argument for the job.

bash  example/unreliable.sh 0.8 0.1 20190808
```

With loop days, we could simply run the following.

```
bash loopDays.sh --state_dir ~/.loopDays/jobstate --look_back 7  --offset 1 --job_name unr_job --max_attempts 3 example/unreliable.sh 0.8 0.1

```
