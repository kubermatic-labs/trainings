#source this file to start ssh-agent with defined SSH key

eval `ssh-agent`
echo "ssh-agent started!"

FOLDER=$(dirname $0)
PK_FILE=$FOLDER/../../.secrets/id_rsa

echo "set permissions $PK_FILE"
chmod 0600 $PK_FILE

echo "add $PK_FILE"
ssh-add $PK_FILE