#!/bin/bash
source dev-config
LOG_FILE=dev-deploy.log
echo "Starting deployment" > $LOG_FILE 

# Set variables in docker-compose.yml.  This is sort of a hack. Need
# to find out why docker stack deploy doesn't substitute env vars
# properly and fix. If it is not supported, then below method can be
# used.
sed -i 's@${USER}@'"$USER"'@g' dev-compose.yml
sed -i 's@${SHARED_DIR}@'"$SHARED_DIR"'@g' dev-compose.yml
sed -i 's@${WORKDIR}@'"$WORKDIR"'@g' dev-compose.yml
sed -i 's@${NGINX}@'"$NGINX"'@g' dev-compose.yml
sed -i 's@${FACEBOOK_APP_ID}@'"$FACEBOOK_APP_ID"'@g' dev-compose.yml
sed -i 's@${FACEBOOK_SECRET_KEY}@'"$FACEBOOK_SECRET_KEY"'@g' dev-compose.yml
sed -i 's@${GOOGLE_APP_ID}@'"$GOOGLE_APP_ID"'@g' dev-compose.yml
sed -i 's@${GOOGLE_SECRET_KEY}@'"$GOOGLE_SECRET_KEY"'@g' dev-compose.yml
sed -i 's@${GA_PROPERTY_ID}@'"$GA_PROPERTY_ID"'@g' dev-compose.yml
sed -i 's@${GOOGLE_TRANSLATE_APP_ID}@'"$GOOGLE_TRANSLATE_APP_ID"'@g' dev-compose.yml
sed -i 's@${MAILCHIMP_LIST_ID}@'"$MAILCHIMP_LIST_ID"'@g' dev-compose.yml
sed -i 's@${MAILCHIMP_API_KEY}@'"$MAILCHIMP_API_KEY"'@g' dev-compose.yml
sed -i 's@${GOOGLE_STORAGE_ACCESS_KEY_ID}@'"$GOOGLE_STORAGE_ACCESS_KEY_ID"'@g' dev-compose.yml
sed -i 's@${GOOGLE_STORAGE_SECRET_ACCESS_KEY}@'"$GOOGLE_STORAGE_SECRET_ACCESS_KEY"'@g' dev-compose.yml
sed -i 's@${NEWRELIC_API_KEY}@'"$NEWRELIC_API_KEY"'@g' dev-compose.yml
sed -i 's@${NEWRELIC_NAME}@'"$NEWRELIC_NAME"'@g' dev-compose.yml
sed -i 's@${MAILER_USER}@'"$MAILER_USER"'@g' dev-compose.yml
sed -i 's@${MAILER_PASSWORD}@'"$MAILER_PASSWORD"'@g' dev-compose.yml
sed -i 's@${MAILER_DOMAIN}@'"$MAILER_DOMAIN"'@g' dev-compose.yml


# Check whether the key is present in given path
ls $SSH_KEY
return_code=$?
if [[ $return_code -ne 0 ]];then
    echo "WARNING: No SSH key present in given path, pls confirm and start deploy again" | tee -a $LOG_FILE  
    exit 1 
fi

#Change mode of ssh key
chmod 600 $SSH_KEY

nodes=(${ELASTIC} ${POSTGRES} ${SW_APP} ${COUCH})
echo "LOG: Nodes are ${nodes[@]}" >> $LOG_FILE 

# Remove duplicate host ips 
unique_hosts=($(echo "${nodes[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

# Remove master ip from unique_hosts
hosts=()
for value in "${unique_hosts[@]}"
do
    [[ $value != $NGINX ]] && hosts+=($value)
done


echo "LOG: Hosts are ${hosts[@]}" >> $LOG_FILE 

labels=("elasticsearch=true" "postgres=true" "app=true" "couchbase=true")

sudo docker swarm init --advertise-addr ${NGINX}
return_code=$?
if [[ return_code -ne 0 ]];then
    echo "WARNING: This host is already part of swarm. Please leave," | tee -a $LOG_FILE 
    echo "to leave run the following command on this host, and run bash deploy.sh again" | tee -a $LOG_FILE  
    echo "    sudo docker swarm leave -f    "  | tee -a $LOG_FILE
    echo "Stopping deployment" >> $LOG_FILE
    exit 1 
fi
echo "LOG: This host set as swarm master" | tee -a $LOG_FILE 
          
# label current node as nginx
sudo docker node update --label-add "nginx=true" $(hostname)
echo "LOG: Labeled master node  as nginx=true">> $LOG_FILE 

# Get the token to join the swarm as worker and construct the joining command
# This will be run in all the other machines 
join_token=$(sudo docker swarm join-token --quiet worker)

# Add each unique host to swarm
host_count=${#hosts[@]}
echo "LOG: ${host_count} hosts to join" >> $LOG_FILE 

for((index=0;index<$host_count;++index));do
    return_code=123
    try_count=1
    while [ $return_code -ne 0 ]
    do
        echo "LOG: Going to ssh to ${hosts[$index]} and set it as a worker" >> $LOG_FILE
        join_command="sudo docker swarm join --token  $join_token --advertise-addr ${hosts[$index]} ${NGINX}:2377"
        echo $join_command >> $LOG_FILE
        return_msg=$(ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${USER}@${hosts[$index]} ${join_command} 2>&1)
        return_code=$?
	    echo "LOG: Return code is $return_code" >> $LOG_FILE 

        if [ $return_code -ne 0 ]; then
        
               repeat=0
               while [ $repeat = 0 ]
               do
                   if [[ "$return_msg" =~ "This node is already part of a swarm" ]]; then
                       echo "${hosts[$index]} is already part of a swarm. Please leave" | tee -a $LOG_FILE
                       echo "the current swarm to use this host.To leave, run the following" | tee -a $LOG_FILE
                       echo "command on that host" | tee -a $LOG_FILE
                       echo "    sudo docker swarm leave -f    " | tee -a $LOG_FILE
                   fi

                   if [[ "$return_msg" =~ "Timeout was reached before node joined" ]]; then
                       echo "${hosts[$index]} Cannot communicate with swarm manager ($NGINX).Please" | tee -a $LOG_FILE
                       echo "ensure that $NGINX is configured to allow incomming traffic through " | tee -a $LOG_FILE
                       echo "PORT 2377. Also make sure that ports 7946 and 4789 are also configured properly" | tee -a $LOG_FILE
                   fi

                   if [[ $return_code = 255 ]];then
                       echo "Cannot ssh to ${hosts[$index]}" | tee -a $LOG_FILE
                   fi

                   if [[ "$return_msg" =~ "docker: command not found" ]]; then
                       echo "docker not installed in ${hosts[$index]}"| tee -a $LOG_FILE
                       echo "Pls install docker "| tee -a $LOG_FILE
                   fi
                   
                   echo "=====================================================" | tee -a $LOG_FILE
                   echo "Select continue after the problemm is fixed, to continue the deployment or " | tee -a $LOG_FILE
                   echo "select quit to stop the process (Note that selecting 'quit' will rollback the network created by the script)" | tee -a $LOG_FILE

                   echo "1) Problem fixed,  contnue " | tee -a $LOG_FILE
                   echo "2) Quit" | tee -a $LOG_FILE
                   
                   echo -e "Choose 1 or 2 :" | tee -a $LOG_FILE
                   read answer
                   echo "Chose $answer"  >> $LOG_FILE
                   case $answer in
                       1) echo "This will resume the deployment from this point" | tee -a $LOG_FILE
                          echo "Enter 'c' to confirm OR 'b' to goback" | tee -a $LOG_FILE
                          read continue

                          case $continue in
                              c) try_count=1
                                 repeat=1 
                          esac;;

                   
                       2) echo "Going Roll back"  | tee -a $LOG_FILE
                      
                          # Leave all joined nodes
	                      leave_command="sudo docker swarm leave -f"
	                      for ((i=$index;i>=0;--i));do
		                      ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${USER}@${hosts[$i]} ${leave_command}
	                      done
	                      sudo docker swarm leave -f
                          exit 1
                          
                     esac
                  done
          
         fi
    done
    
    echo "LOG: ${host[$index]} joined to cluster as worker" | tee -a $LOG_FILE
     
done

# Label all nodes 
for((indx=0;indx<4;++indx)); do 
    echo "LOG: Going to label ${nodes[$indx]} as ${labels[$indx]}" >> $LOG_FILE 
    
    sudo docker node  update --label-add ${labels[$indx]} $(ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${USER}@${nodes[$indx]} hostname)
    return_code=$?    
	echo "LOG: Label Return code is $return_code" >> $LOG_FILE 

    if [ $return_code == 0 ]; then
        echo "LOG: ${node[$indx]} node labeled as ${labels[$indx]}" >> $LOG_FILE 
    else
        echo "LOG: ${node[$indx]} node NOT labeled Successfully" >> $LOG_FILE 
    fi
done

# Create shared directory in app host
echo "LOG: Going to create shared directory in ${SW_APP}" >> $LOG_FILE 
ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${USER}@${SW_APP} "mkdir -p ${SHARED_DIR}/log ${SHARED_DIR}/system ${SHARED_DIR}/tmp"
echo "LOG: Created ${SHARED_DIR} in ${SW_APP} " >> $LOG_FILE 

# Create data directory in postgres
echo "LOG: Going to create data directory in ${POSTGRES}" >> $LOG_FILE
ssh -i ${SSH_KEY} -o StrictHostKeyChecking=no ${USER}@${POSTGRES} "sudo mkdir -p /etc/storyweaver/data"
echo "LOG: Created /etc/storyweaver/data in ${POSTGRES} " >> $LOG_FILE

# Deploy
echo "LOG: Going to DEPLOY........wait a while"  | tee -a $LOG_FILE
sudo docker stack deploy -c dev-compose.yml storyweaver | tee -a $LOG_FILE 
echo "Please wait for some time ......"
sleep 180

# Check the status of the stack and its work
source  dev-healthcheck.sh

echo "LOG: Go to the ${NGINX} with your browser "  | tee -a $LOG_FILE 
