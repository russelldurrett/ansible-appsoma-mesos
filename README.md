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
    * Python2.7, Java 6 and 7, and NodeJS to run jobs and services
    * [Docker](https://www.docker.com/) for containerized applications
    
* All nodes have access to an NFS-mounted data directory, shared across all masters and slaves, to share job data.
* All nodes have a series of initial users created (see `playbook_vars/users.yml`) to use when running Welder jobs.
* When using a cloud provider (Amazon EC2-only for now), you get dynamic access to your cloud, with node creation and management 

## Prerequisites

Ansible will run from any host with network access to your cluster.  For a cloud provider, this requires internet access. 
For an intranet, your host will have to have access to the LAN (local or VPN) and SSH access.

Ansible can be installed on Ubuntu/Debian by adding the ansible PPA repository:

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

To configure your cluster, you'll have to copy the `playbook_vars/required_vars.template` to `playbook_vars/required_vars.yml`
and edit to suit.  The only absolute customization you must do is the `cluster_name` variable.  This will be the root name of all your instances.


## How To install on EC2

### What you'll need

This script will create 1 NFS server with an EBS data volume and a new VPC, as well as the master and slave nodes.  Make sure your subscription has enough resources available
To run with Amazon EC2, you'll have to collect an access credential (Access Key/Secret Key, or Access Key ID and Secret Access Key, either name might appear)
You'll also need to register a keypair on EC2, either with the AWS CLI or on the web interface, on the EC2 Dashboard under "Network & Security". 

You'll also need to select an AWS region and availability zone to install the cluster in.

If you use Route53 to manage a public domain name, you can assign DNS entries to your newly booted nodes. You'll need the name of the zone you want route53 to add new nodes to.
 
* Copy `playbook_vars/aws_secret_vars.yml.template` to `playbook_vars/aws_secret_vars.yml` and edit the values to match your AWS account
    * Remember not to include the AWS keys in a git repo!
    * If you haven't already, copy `playbook_vars/required_vars.template` to `playbook_vars/required_vars.yml`
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

## How To install with an existing cluster

*Still in development*

## To Do

* Cluster shutdown and cleanup 
* Existing cluster support (mostly configuring values to be non-ec2 specific, and setting rules for host file variables)
* Supporting other clouds (GCE, OpenStack, Azure)
* Dynamic node management (add and remove capacity when needed)
* Dynamic user management
