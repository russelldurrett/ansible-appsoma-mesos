export AWS_ACCESS_KEY=`grep -m 1 "aws_access_key:" playbook_vars/aws_secret_vars.yml | cut -d '"' -f 2`
export AWS_SECRET_KEY=`grep -m 1 "aws_secret_key:" playbook_vars/aws_secret_vars.yml | cut -d '"' -f 2`
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_KEY}"
