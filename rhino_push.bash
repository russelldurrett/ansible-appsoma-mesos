#!/usr/bin/env bash
if [ "$1" == "" ] || [ "$2" == "" ]; then
	echo "USAGE: welder_push.bash BRANCH CLUSTER"
	exit 1
fi
BRANCH=$1
CLUSTER=$2
echo "PUSHING RHINO BRANCH $BRANCH to CLUSTER $CLUSTER"
ansible-playbook --private-key ~/vmmy.pem -i inventory/ec2Inventory.py playbooks/rhino_playbook.yml -e "rhino_version=$BRANCH cluster_name=$CLUSTER"
