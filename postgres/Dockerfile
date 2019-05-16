FROM ubuntu:14.04

RUN apt-key adv --keyserver keyserver.ubuntu.com --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ precise-pgdg main" > /etc/apt/sources.list.d/pgdg.list
RUN apt-get update && apt-get -y -q install python-software-properties software-properties-common \
    && apt-get -y -q install postgresql-9.3 postgresql-client-9.3 postgresql-contrib-9.3

ARG user_name='spp_user'
ARG user_pwd='grablempga'
ENV HOST='sw-app'
ENV USER=$user_name

USER postgres
RUN    /etc/init.d/postgresql start &&\
    psql --command "CREATE USER $user_name superuser;" &&\
    psql --command "ALTER USER $user_name WITH LOGIN;" &&\
    psql --command "ALTER USER $user_name WITH PASSWORD '$user_pwd';" &&\
    psql --command "GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA public TO $user_name;" &&\
    psql --command "GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO $user_name;" &&\
    psql --command "GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO $user_name;" &&\
    psql --command "GRANT ALL ON ALL TABLES IN SCHEMA public TO $user_name;"
  
RUN sed -i "90i\local   all         $user_name                      trust" /etc/postgresql/9.3/main/pg_hba.conf

EXPOSE 5432


USER postgres
RUN service postgresql restart

ADD start.sh /tmp/
CMD ["/bin/bash", "-l", "/tmp/start.sh"]

