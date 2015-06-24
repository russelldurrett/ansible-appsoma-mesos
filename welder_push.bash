#!/usr/bin/env bash
if [ "$1" == "" ] || [ "$2" == "" ]; then
	echo "USAGE: welder_push.bash BRANCH CLUSTER"
fi
BRANCH=$1
CLUSTER=$2
echo "PUSHING BRANCH $BRANCH to CLUSTER $CLUSTER"
ansible-playbook --private-key ~/vmmy.pem -i inventory/ec2Inventory.py playbooks/welder_playbook.yml -e "welder_version=$BRANCH cluster_name=$CLUSTER"
