#!/usr/bin/env bash

### variable definitions

export AWS_ACCESS_KEY_ID="ABCDEFGHIJKLMNOPQRSTUWXYZ"
export AWS_DEFAULT_REGION="eu-west-1"
export AWS_SECRET_ACCESS_KEY="abcdefghijklmnopqrstuwxyz1234567890"

f_instance="instances"


### functions 

# get instance ids out of AWS:

function aws_ids() {

    for instance_id in $(aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --output text ) 
    do
        echo "Instance ${instance_id} status: $(aws ec2 describe-instances --instance-ids ${instance_id} --query 'Reservations[*].Instances[*].State.Name' --output text)"
    done
} 

# get instance ids out of file:

function file_ids() {

    local _file=${1}

    while read line
    do
        instance_id=$(echo ${line} | grep -o "i-[a-f0-9]\{8\}")  
        tag_name=$(aws ec2 describe-instances --instance-ids ${instance_id} --query 'Reservations[].Instances[].[Tags[?Key==`Name`].Value]' --output text)
        echo "Instance ${instance_id} | ${tag_name} | status: $(aws ec2 describe-instances --instance-ids ${instance_id} --query 'Reservations[*].Instances[*].State.Name' --output text)"
    done < <(grep -Ev "#" ${_file})
}

function getStatus() {

#   [ -z $1 ] && { echo "No argument given. Exitting..."; exit 1; }
    local _id=${1}
    
    retStatus=$(aws ec2 describe-instances --instance-ids ${_id} --output text --query 'Reservations[*].Instances[*].State.Name')
    echo ${retStatus}
}

function wait_for() {

    local _stat_param=${1}
    local _id=${2}

    while [ "$(getStatus ${_id})" != "${_stat_param}" ]
    do
        sleep 1
        echo -n '.'
    done
}

function stop_instances() {

    local _file=${1}

    while read line
    do
        instance_id=$(echo ${line} | grep -o "i-[a-f0-9]\{8\}") 
        aws ec2 stop-instances --instance-ids ${instance_id} 
    done < <(grep -Ev "#" ${_file})
}

function start_instances() {

    local _file=${1}
    
    while read line
    do
        instance_id=$(echo ${line} | grep -o "i-[a-f0-9]\{8\}") 
        aws ec2 start-instances --instance-ids ${instance_id} 
    done < <(grep -Ev "#" ${_file})
}


### main

case "${1}" in
    -R|--start) start_instances ${f_instance} ;;
    -P|--stop) stop_instances ${f_instance} ;;
    *) echo "Choose and option: [ -R/--start,run | -P/--stop,pause ]"; exit 0 ;;
esac


