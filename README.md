# **Appsoma Welder cluster deployment**


## Description


Deploys software for a scalable Mesos cluster with Marathon, HAProxy and Appsoma's Welder job launcher and Rhino batch job Mesos framework.

### What you get

Successfully running this playbook will create:

* An [Apache Mesos](http://mesos.apache.org/) cluster with 1 or more master nodes and 1 or more slave nodes
* [Apache Zookeeper](https://zookeeper.apache.org/) to provide service registration and fault tolerance
* The [Appsoma Rhino](https://github.com/appsoma/rhino) batch processing framework registered in Mesos
* The [Appsoma Welder](https://github.com/appsoma/welder) compute Application Management service 
* The [Mesosphere Marathon](https://github.com/mesosphere/marathon) service management framework registered with Mesos, and configured with [HAProxy](http://www.haproxy.org/) 
* Master and slave nodes are configured with:
    * Python2.7, OpenJDK Java 6, 7, and 8, and NodeJS to run jobs and services
    * [Docker](https://www.docker.com/) for containerized applications
    
* All nodes have access to an NFS-mounted data directory, shared across all masters and slaves, to share job data.
* All nodes have a series of initial users created (see `cluster_vars/users.yml.template`) to use when running Welder jobs.
* When using a cloud provider (Amazon EC2-only for now), you get dynamic access to your cloud, with node creation and management 

## Prerequisites

Ansible will run from any host with network access to your cluster.  For a cloud provider, this requires internet access. 
For an intranet, your host will have to have access to the LAN (local or VPN) and SSH access.

Ansible can be installed on Ubuntu/Debian by adding the Ansible PPA repository:

	sudo apt-get install software-properties-common
	sudo apt-add-repository ppa:ansible/ansible
	sudo apt-get update
	sudo apt-get install ansible python-boto
	
Or on RH/Centos by using the [EPEL libary](http://fedoraproject.org/wiki/EPEL):

    sudo yum install ansible python-boto
	
Don't forget about Boto, the Amazon AWS client module for python.  The standard distro package should be sufficient.

# Installation

 
	git clone git@github.com:appsoma/ansible-appsoma-mesos.git
	cd ansible-appsoma-mesos

To configure your cluster, you'll have to create a directory with the name of your cluster: `cluster_vars/<cluster_name>`.  
In this directory, you should create `cluster_vars/<cluster_name>/required_vars.yml` and `cluster_vars/<cluster_name>/users.yml`
from the templates in `cluster_vars/required_vars.yml.template` and `cluster_vars/users.yml.template`.  
The only absolute customization you must do is the `cluster_name` variable.  This will be the root name of all your instances.

To use HAProxy with SSL, set the flag in `required_vars.yml` and create a file called `cluster_vars/<cluster_name>/haproxy.pem`


## How To install on EC2 

### What you'll need

This script will create 1 NFS server with an EBS data volume and a new VPC, as well as the master and slave nodes.  Make sure your subscription has enough resources available
To run with Amazon EC2, you'll have to collect an access credential (Access Key/Secret Key, or Access Key ID and Secret Access Key, either name might appear)
You'll also need to register a [keypair on EC2](http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html). 

You'll also need to select an AWS region and availability zone to install the cluster in.

If you use Route53 to manage a public domain name, you can assign DNS entries to your newly booted nodes. You'll need the name of the zone you want route53 to add new nodes to.
 
* Copy `cluster_vars/aws_secret_vars.yml.template` to `cluster_vars/<cluster_name>/aws_secret_vars.yml` and edit the values to match your AWS account
    * Remember not to include the AWS keys in a git repo!
    * If you haven't already, copy `cluster_vars/required_vars.yml.template` and `cluster_vars/users.yml.template`
    * Set `cloud_provider: "ec2"` in `cluster_vars/<cluster_name>/required_vars.yml`
    * Be sure to change the `ec2_key_name`, `ec2_region`, and `ec2_zone` keys to match your information
    * If you want to use Route53 DNS, make sure `use_route53: true` and `route53_zone` is set to your DNS zone.
    * Set the instance types, data volume size and type, and private lan subnets to your liking.  Remember these will cost you while running.

Next, you'll have to set up the EC2 environment.  If you have an existing Boto config (`/etc/boto.cfg`, `~/.boto`, or `~/.aws/credentials`), you can skip this

    source setup_amazon_env.bash
    
Now, test that you can access the EC2 dynamic inventory.  This should produce a list of some contents of your EC2 account.  
Any errors messages here will prevent you from accessing EC2 and using this playbook:

    inventory/ec2Inventory.py --list

### Running
If your private key is in ~/.ssh, you don't need the `--private-key` option.  You may want to edit your user ssh config in `~/.ssh/config` or your system ssh config `/etc/ssh/ssh_config` to set `StrictHostKeyChecking no`. 
This will remove the warnings (which require you to type `yes`) when you connect to a brand new node on Amazon.
 
Now to run the playbook from scratch: 

    ansible-playbook --private-key ~/mykey.pem -i inventory/ec2Inventory.py create_cluster_playbook.yml -e "master_count=<# of masters> slave_count=<# of slaves>"

You can safely re-run this command multiple times, in the event of an Amazon communication outage, or an error in variables.

If you edit `playbook_vars/users.yml`, you can update the entire cluster by running:
    
    ansible-playbook --private-key ~/mykey.pem -i inventory/ec2Inventory.py sync_users.yml
    
This will add new users, and update existing users (and their passwords).  This fixed password management is the best solution short of a user directory system. (See [To do items](#to-do))

### Troubleshooting
* SSH errors
    * Make sure your SSH key has the correct permissions (`0600`).  Set `StrictHostKeyChecking no` in `/etc/ssh/ssh_config`
* Missing variable values
    * Check the `cluster_vars/<cluster_name>` files, and ensure that you have customized the values for `aws_secret_vars.yml`, `required_vars.yml`, and `users.yml`
    * Rerun.  You can use the Ansible retry if it offers as well.
* Timeouts or `receive failed` messages
    * Custom repositories may not be responding (Docker, Mesosphere, Github. possibly core repos or cloud-served repos).
    * You may need to check the nodes internet connectivity or wait to rerun.  You can use the ansible retry if it offers as well.
* Timeouts or errors from AWS or Boto
    * Check that your `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables are set, or your boto.cfg is set up.
    * Check connectivity of the host you are running on to AWS (AWS may also suffer temporary outages too).
    * Rerun. You can use the Ansible retry if it offers as well.

    
## How To install with an existing cluster

### What you'll need

You'll need to construct an Ansible inventory file with a few attributes for the nodes in your cluster


### Running

If your private key is in ~/.ssh, you don't need the `--private-key` option.  You may want to edit your user ssh config in `~/.ssh/config` or your system ssh config `/etc/ssh/ssh_config` to set `StrictHostKeyChecking no`. 
This will remove the warnings (which require you to type `yes`) when you connect to a brand new node on Amazon.
 
Now to run the playbook from scratch: 

    ansible-playbook --private-key ~/mykey.pem -i cluster_vars/<cluster_name>/inventory create_cluster_playbook.yml -e "cluster_name=<cluster_name>"

You can safely re-run this command multiple times, in the event of an Amazon communication outage, or an error in variables.

If you edit `cluster_vars/<cluster_name>/users.yml`, you can update the entire cluster by running:
    
    ansible-playbook --private-key ~/mykey.pem -i cluster_vars/<cluster_name>/inventory sync_users.yml -e "cluster_name=<cluster_name>"

### Troubleshooting

* Missing variable values
    * Check the `cluster_vars/<cluster_name>` files, and ensure that you have customized the values for `inventory`, `required_vars.yml`, and `users.yml`
    * Rerun.  You can use the Ansible retry if it offers as well.
* Timeouts or `receive failed` messages
    * Custom repositories may not be responding (Docker, Mesosphere, Github. possibly core repos or cloud-served repos).
    * You may need to check the nodes internet connectivity or wait to rerun.  You can use the Ansible retry if it offers as well.
    

## Connecting to the cluster
The welder server will be listening on the master at the port specified in roles/ansible-welder/defaults/main.yml ( Defaults to `8890`)

The users you have defined in `cluster_vars/<cluster_name>/users.yml` are available to log in to Welder, using the password defined.  These users do not have SSH access to the cluster.

The `welder_group:` section of `cluster_vars/<cluster_name>/users.yml` defines a group that all Welder users will be a part of.

## Developing with Welder
The Welder source is checked out into `/opt/welder` on the master. The service can be started by running `service welder start` and `service welder-widgets start`. 
Logs for the service are saved in `/var/log/appsoma/welder.log`.

The Welder users can be configured for ssh login by setting an authorized key in `~/.ssh/authorized_keys`.  Each user's home directory has a scratch space on the data dir in `~/data`


## To Do

* Cluster shutdown and cleanup 
* Existing cluster support (mostly configuring values to be non-ec2 specific, and setting rules for host file variables)
* Supporting other clouds (GCE, OpenStack, Azure)
* Dynamic node management (add and remove capacity when needed)
* Dynamic user management
