#!/bin/bash
LOG_FILE=deploy.log

# Check whether the nginx running correctly

# Get the container id of nginx
while [ -z $CONTAINER_ID ]; do
    CONTAINER_ID=$(sudo docker ps -qf name=storyweaver_sw-nginx)
    echo "LOG: Nginx container id is : $CONTAINER_ID" >> $LOG_FILE 
    sleep 10
done

#Try to restart nginx service
RETURN_MSG=$(sudo docker exec -t  $CONTAINER_ID service nginx restart)
echo "LOG: Return message of nginx service restart is : $RETURN_MSG" | tee -a $LOG_FILE

#check wether have DNS issue if have redeploy the stack
if [[ "$RETURN_MSG" =~ "host not found in upstream" ]]; then
        
    # Remove existing storyweaver stack
    echo "LOG: Going to remove existing stack" | tee -a $LOG_FILE   
    sudo docker stack rm storyweaver | tee -a $LOG_FILE 

    # Wait for a while for remove stack
    echo "LOG: Removing....wait...a..while"
    sleep 60


    # Redeploy the stack
    echo "Going to Redeploy" | tee -a $LOG_FILE   
    sudo docker stack deploy -c dev-compose.yml storyweaver | tee -a $LOG_FILE 
    sleep 120
    
fi
