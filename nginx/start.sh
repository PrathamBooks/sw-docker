#!/bin/bash
echo $HOST_IP
openssl req -new -newkey rsa:4096 -days 365 -nodes -x509 \
    -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=$HOST_IP" \
    -keyout /self-signed.key  -out /self-signed.cert
sed -i "10i\  server_name $HOST_IP" /etc/nginx/sites-available/spp.conf
service nginx restart
tail -f  /var/log/nginx/access.log&
while true
do
    service nginx status
    if [ $? -ne 0 ]; then
        service nginx restart
    fi
    sleep 60
done

