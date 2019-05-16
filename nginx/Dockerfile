FROM nginx
SHELL ["/bin/bash","-l","-c"]

ENV HOST_IP=0.0.0.0

# Install acme.sh for ssl
RUN apt-get update && apt-get install curl cron nano -y
RUN curl https://get.acme.sh | sh

COPY nginx.conf /etc/nginx/nginx.conf
COPY spp.conf /etc/nginx/sites-available/spp.conf

ADD start.sh /


RUN mkdir /etc/nginx/sites-enabled &&\
    ln -s /etc/nginx/sites-available/spp.conf /etc/nginx/sites-enabled/spp.conf

EXPOSE 80 443

CMD ["/bin/bash", "-l", "start.sh"]

