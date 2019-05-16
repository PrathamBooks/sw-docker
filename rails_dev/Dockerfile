FROM ubuntu:18.04 
SHELL ["/bin/bash","-l","-c"]

# Installing rvm and ruby 2.1.4 version

RUN apt-get update
RUN apt-get install -y imagemagick gpg

RUN gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
RUN apt-get update
RUN apt-get install -y curl
RUN curl -sSL https://rvm.io/mpapis.asc | gpg --import -
RUN curl -sSL https://get.rvm.io | bash -s stable
RUN source /etc/profile.d/rvm.sh
RUN echo "source /etc/profile.d/rvm.sh" >> /root/.bashrc
RUN source /etc/profile.d/rvm.sh && rvm install 2.1.4
RUN source /etc/profile.d/rvm.sh && rvm use 2.1.4 --default

RUN apt-get install -y wget

RUN apt-get install -y software-properties-common

# Install espeak
RUN apt-get install -y espeak libespeak-dev
RUN espeak --version

# Install ffmpeg
RUN apt-get update
RUN apt-get install -y ffmpeg

# Install python packages
RUN apt-get install -y python-pip
RUN pip install BeautifulSoup4
RUN pip install lxml
RUN pip install numpy
RUN pip install aeneas
RUN python -m aeneas.diagnostics
RUN pip install httplib2
RUN pip install --upgrade google-api-python-client
RUN pip install --upgrade oauth2client

RUN apt-get install -y vim

# Install wkhtmltopdf
RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.3/wkhtmltox-0.12.3_linux-generic-amd64.tar.xz &&\
    tar vxf wkhtmltox-0.12.3_linux-generic-amd64.tar.xz &&\
    cp wkhtmltox/bin/wk* /usr/local/bin/
RUN echo "$(wkhtmltopdf --version)"

# Install couchbase-dev packages
RUN wget -O - http://packages.couchbase.com/ubuntu/couchbase.key | apt-key add -
RUN echo "deb http://packages.couchbase.com/ubuntu bionic bionic/main" > /etc/apt/sources.list.d/couchbase.list
RUN apt-get update
RUN apt-get install -y libcouchbase-dev libcouchbase2-bin build-essential

RUN apt-get update &&\
    apt-get install -y  git &&\
    apt-get install -y libpq-dev &&\
    apt-get install -y libmagickwand-dev 

# Install node.js
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - &&\
    apt-get install -y nodejs

# Install  bundler
RUN source /etc/profile.d/rvm.sh && gem install bundler -v 1.17.3

# Install Qt before capybara
RUN apt-get update &&\
    apt-get install -y qt5-default libqt5webkit5-dev gstreamer1.0-plugins-base gstreamer1.0-tools gstreamer1.0-x


RUN apt-get install libmagickwand-6-headers

# Setup packages for building frontend
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - &&\
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list &&\
    apt-get update &&\
    apt-get install yarn


ADD start.sh /

WORKDIR /workdir

#Adds the tzinfo-data gem to get Timezone data
RUN source /etc/profile.d/rvm.sh && gem install tzinfo-data

#RUN apt install -y postgresql-9.5
RUN echo "source /etc/profile.d/rvm.sh" > ~/.bashrc

CMD ["/bin/bash", "-l", "/start.sh"]
