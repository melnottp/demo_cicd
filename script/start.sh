#! /bin/sh
terraform output keypair >> keypair.pem
terraform output --raw kubeconfig_json >> config
chmod 400 keypair.pem
DEMO_BASTION=$(terraform output --raw bastion_public_IP)
SSH_PORT=$(terraform output --raw ssh_port)
ssh -i keypair.pem -o "StrictHostKeyChecking no" -p $SSH_PORT $DEMO_BASTION "mkdir -p ~/.kube" &&
scp -r -i keypair.pem -o "StrictHostKeyChecking no" -P $SSH_PORT config cloud@$DEMO_BASTION:/home/cloud/.kube &&
ssh -i keypair.pem -o "StrictHostKeyChecking no" -p $SSH_PORT $DEMO_BASTION "chmod 400 ~/.kube/config" &&
ssh -i keypair.pem -o "StrictHostKeyChecking no" -p $SSH_PORT $DEMO_BASTION
