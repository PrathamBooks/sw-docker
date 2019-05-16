# Deploy docker containers
StoryWeaver has five services: The storyweaver application (Rails
backend + React frontend), Postgress database, couchbase,
elasticsearch, and nginx.  This documentation will lay out the steps
to deploy StoryWeaver on your server.

## Prerequisites
  - Create required number of vps running ubuntu 18.04. If you are
    going to create one for each service go with five or if you are
    going for single system install, create one.  Note that
    elasticseach requires atleast 4GB of memory so please keep in mind
    when creating servers.
  
  - Open ports TCP 2377, TCP and UDP 7946 and UDP 4789 on all
    machines. These ports are used by docker to communicate between
    nodes. Make sure that the port '80' and '443'(for https) is open
    and accepting connections on the machine intended to run 'nginx'.
  
    On aws, opening ports can be managed by editing the instance's
    security group. See documentation [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-network-security.html#working-with-security-groups).

    On google cloud platform, the necessary firewall rules need to be
    created and assigned to the instances. See [here](https://cloud.google.com/vpc/docs/using-firewalls).

    Documentation for digital ocean can be found [here](https://www.digitalocean.com/docs/networking/firewalls/how-to/configure-rules/)

  - SSH_KEY : An ssh key that can be used to access the machines
    created above. You can create a new key or use an existing
    one. The steps for creating a new key or using an existing one
    differ from provider to provider. Documentation for AWS and GCP
    can be found below.
    - GCP [here](https://cloud.google.com/compute/docs/instances/adding-removing-ssh-keys)
    - AWS [here](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)
    - Digital Ocean [here](https://www.digitalocean.com/docs/droplets/how-to/add-ssh-keys/)
    - E2E Networks [here](https://www.e2enetworks.com/help/knowledge-base/set-up-ssh-keys/)
## Machine Setup

  - Install git and docker on all machines. docker version needs to be
    18.09.1-rc1 or greater.
  
    docker:

    If docker is not already installed then:
    ```
      curl -fsSL https://get.docker.com -o get-docker.sh
      CHANNEL="test" sh get-docker.sh
    ```
    This will also install git. If you are not using this method, you
    can install git using
     ```
      sudo apt-get update 
      sudo apt-get install git
    ```

    If docker is already installed and is running a lower version,
    then do the following to update
    ```
      # Uninstall current version
      sudo apt-get purge docker*

      # Install latest version
      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
      sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic test"
      sudo apt update
      sudo apt install docker-ce
    ```
    Make sure of the install by running
    ```
      docker --version
      git --version
    ```

  - Place the ssh key to server supposed to run nginx service

## Deployment
   This provides dockerized environment for developing 'sw-core' and 'sw-web' projects.

  - ssh into the machine where rails should be run. Let's call this the 'rails server'

  - Clone application  repositories  to a directory called 'workdir' in rails server (This can be any
    directory. see "WORKDIR" in config section given below) 
    ```
    mkdir workdir
    cd workdir
    git clone https://github.com/PrathamBooks/sw-core.git
    git clone https://github.com/PrathamBooks/sw-web.git
    # Make sure "gem tzinfo-data" in Gem file
    ```

  - Edit spp/config/database.yml
    add a new line under 'default' "host: sw-postgres" in it. 
    ```
    #default looks like after edit
    default: &default
    adapter: postgresql
    encoding: unicode
    pool: 5
    database: spp
    timeout: 5000
    username: spp_user
    host: sw-postgres
  
    development:
    <<: *default
    ...
    ...
    ```
  - ssh into the machine where nginx should be run. This node will be
    used as the docker swarm manager. Let's call this the 'nginx server'
  
  - Clone the deployment repository
    ```
      git clone https://github.com/PrathamBooks/sw-docker-new.git
      cd sw-docker-new
    ```

  - Edit the 'dev-config' file and set appropriate values.(Keys are same as in deploy config)
    Difference:
     'WORKDIR' is the absolute path to the directory where 'sw-core' and 'sw-web' are cloned.
     This directory will be mounted into the rails container, so, any files put inside this
     directory will be available inside the container.    
  - Run
    ```
     bash dev-deploy.sh
    ```
  - Login into rails container and build react app
    ```
      docker exec -it <rails containerID> bash
      bash /workdir/sw-core/lib/scripts/build_script.sh
      #update localhost to nginx ip in build script
     ```
    Wait for sometime and then go to the ip address of nginx server
    
### Known issue
In very rare cases just after deployment, containers can have
problems connecting to each other due to internal DNS resolution
issues with docker swarm.  To mitigate this, we check for the
issue after deployment and if it has happened, the containers are
redeployed.
