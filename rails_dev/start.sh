RAILS_PATH=sw-core

cd $RAILS_PATH

RETURN_CODE=1
while [ $RETURN_CODE -ne 0 ]
do
source /etc/profile.d/rvm.sh && export LC_ALL=C.UTF-8 &&\
     export LANG=en_US.UTF-8 &&\
     export LANGUAGE=en_US.UTF-8 &&\
     bundle install
RETURN_CODE=$?
done

sleep 15
source /etc/profile.d/rvm.sh

export LC_ALL=C.UTF-8
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export NEWRELIC_API_KEY=$NEWRELIC_API_KEY
export NEWRELIC_NAME=$NEWRELIC_NAME
export MAILER_USER=$MAILER_USER
export MAILER_PASSWORD=$MAILER_PASSWORD
export MAILER_DOMAIN=$MAILER_DOMAIN
#export RAILS_ENV=production
export rootUrl=$HOST_IP
export FACEBOOK_APP_ID=$FACEBOOK_APP_ID
export FACEBOOK_SECRET_KEY=$FACEBOOK_SECRET_KEY
export GOOGLE_SIGNIN_APP_ID=$GOOGLE_SIGNIN_APP_ID
export GOOGLE_SECRET_KEY=$GOOGLE_SECRET_KEY
export GA_PROPERTY_ID=$GA_PROPERTY_ID
export GOOGLE_APP_ID=$GOOGLE_TRANSLATE_APP_ID
export MAILCHIMP_LIST_ID=$MAILCHIMP_LIST_ID
export MAILCHIMP_API_KEY=$MAILCHIMP_API_KEY
export DEVISE_SECRET_KEY_BASE=$DEVISE_SECRET_KEY_BASE
export SECRET_KEY_BASE=$SECRET_KEY_BASE
export GOOGLE_STORAGE_ACCESS_KEY_ID=$GOOGLE_STORAGE_ACCESS_KEY_ID
export GOOGLE_STORAGE_SECRET_ACCESS_KEY=$GOOGLE_STORAGE_SECRET_ACCESS_KEY
export COUCHBASE_IP=$COUCHBASE_IP
export ELASTICSEARCH_URL=sw-elasticsearch
export COUCHBASE_IP=sw-couchbase



ln -s /shared/system/ $RAILS_PATH/public/system
ln -s /shared/tmp/ $RAILS_PATH/tmp
ln -s /shared/log/ $RAILS_PATH/log 

#Wait until postgres is up and accepting connections on port 5432
while ! timeout 1 bash -c "echo > /dev/tcp/sw-postgres/5432"; do sleep 10; done

echo "db:create"
bundle exec rake db:create
echo "db:migrate"
bundle exec rake db:migrate -t
echo " db:seed "
bundle exec rake db:seed -t
# bundle exec rake illustrations:reindex
# bundle exec rake blog_posts:reindex
# bundle exec rake users:reindex
# bundle exec rake stories:reindex
# bundle exec rake lists:reindex
bin/delayed_job  restart
bundle exec puma
#bundle exec rake swagger:docs

# echo "db:seed"
# bundle exec rake db:seed
# echo "db:seed:development"
# bundle exec rake db:seed:development:users
# bundle exec rake searchkick:reindex:all
#tail -f /shared/log/production.log
 
