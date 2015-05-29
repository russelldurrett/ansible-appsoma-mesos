# **Appsoma Welder cluster deployment**


## Description


Deploys software for a scalable Mesos cluster with Marathon, HAProxy and Appsoma's Welder job launcher and Rhino batch job Mesos framework.


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
To run with Amazon EC2, you'll have to collect an access credential (Access Key/Secret Key, or Access Key ID and Secret Access Key, either name might appear)
You'll also need to register a keypair on EC2, either with the AWS CLI or on the web interface, on the EC2 Dashboard under "Network & Security". 

You'll also need to select an AWS region and availability zone to install the cluster in.

If you use Route53 to manage a public domain name, you can assign DNS entries to your newly booted nodes. You'll need the name of the zone you want route53 to add new nodes to.
 
* Copy `playbook_vars/aws_secret_vars.yml.template` to `playbook_vars/aws_secret_vars.yml.template` and edit the values to match your AWS account
* If you haven't already, copy `playbook_vars/required_vars.template` to `playbook_vars/required_vars.yml`
    * Be sure to change the `ec2_key_name`, `ec2_region`, and `ec2_zone` keys to match your information
    * If you want to use Route53 DNS, make sure `use_route53` is set to `True` and `route53_zone` is set to your DNS zone.
    * Set the instance types, data volume size and type, and private lan subnets to your liking.  Remember these will cost you while running.

Next, you'll have to set up the EC2 environment.  If you have an existing Boto config (`/etc/boto.cfg`, `~/.boto`, or `~/.aws/credentials`), you can skipt this

    source set_amazon_env.bash
    
Now, test that you can access the EC2 dynamic inventory.  This should produce a list of some contents of your EC2 account.  
Any errors messages here will prevent you from accessing EC2 and using this playbook:

    inventory/ec2Inventory.py --list

### Running
Now to run the playbook from scratch (note, if your private key is in ~/.ssh, you don't need the `--private-key` option):

    ansible-playbook --private-key ~/mykey.pem -i inventory/ec2Inventory.py create_cluster_playbook.yml -e "master_count=<# of masters> slave_count=<# of slaves>"

You can safely re-run this command multiple times, in the event of an Amazon communication outage, or an error in variables.

## How To install with an existing cluster

*Still in development*



## How To install Welder

*Still in development*

## Known Issues

* Existing cluster support (mostly configuring values to be non-ec2 specific, and setting rules for host file variables)
* Supporting other clouds (GCE, OpenStack, Azure)
* Dynamic node management (add and remove capacity when needed)
