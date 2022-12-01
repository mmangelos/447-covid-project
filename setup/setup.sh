#!/bin/bash

# to function properly, script must be run as the developer's user
if [[ $EUID -eq 0 ]]
then
        1>&2 echo "ERROR: do not run this script as root!"
        1>&2 echo "Instead, type your password when prompted."
        exit 1
fi

# ensure the user does not have a ~/.bash_profile
if [[ -f $HOME/.bash_profile ]]
then
        echo "The file $HOME/.bash_profile does not exist by default"
        echo "To guarantee this script will work, may I remove it?"
        echo
        read -p "Y/N: " choice

        if [[ $choice -eq 'Y' || $choice -eq 'y' ]]
        then
                rm  -f $HOME/.bash_profile
        else
                echo
                echo "This script cannot continue; to proceed, please restore"
                echo "the default user configuration and customize your environment"
                echo "after running the script"
                exit 1
        fi
fi

# ensure that the user has a stock profile
if &>/dev/null diff $HOME/.profile /etc/skel/.profile
then
        echo
        echo "Your $HOME/.profile is different from the distribution default"
        echo "To guarantee this script will work, may I restore it?"
        echo
        read -p "Y/N: " choice

        if [[ $choice -eq 'Y' || $choice -eq 'y' ]]
        then
                cp /etc/skel/.profile $HOME/.profile
        else
                echo
                echo "This script cannot continue; to proceed, please restore"
                echo "the default user configuration and customize your environment"
                echo "after running the script"
                exit 1
        fi
fi


# ensure that the user has a stock bashrc
if &>/dev/null diff $HOME/.bashrc /etc/skel/.bashrc
then
        echo
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo "Your $HOME/.bashrc is different from the distribution default"
        echo "To guarantee this script will work, may I restore it?"
        echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        echo
        read -p "Y/N: " choice

        if [[ $choice -eq 'Y' || $choice -eq 'y' ]]
        then
                cp /etc/skel/.bashrc $HOME/.bashrc
        else
                echo
                echo "This script cannot continue; to proceed, please restore"
                echo "the default user configuration and customize your environment"
                echo "after running the script"
                exit 1
        fi
fi


# refresh apt cache
sudo apt update -y

# install ubuntu package dependencies
sudo apt install -y curl npm python3-pip mysql-server libmysqlclient-dev redis git build-essential

# install python dependencies
pip install --user mysql mysql-connector mysqlclient

# install node dependencies (must be redis 3.0)
npm install mysql node-static querystring redis@3.0.0

# install node version manager (nvm)
rm -rf $HOME/.nvm
cd $HOME && git clone https://github.com/nvm-sh/nvm.git .nvm

# use latest nvm version
cd $HOME/.nvm && git -c advice.detachedHead=false checkout v0.38.0 && cd -

# automatically enter the node version manager environmment when opening a new
# bash shell
cat >> $HOME/.bashrc <<EOF
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && . "\$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "\$NVM_DIR/bash_completion" ] && . "\$NVM_DIR/bash_completion"  # This loads nvm bash_completion
EOF

# load nvm
export "NVM_DIR=$HOME/.nvm"
. "$NVM_DIR/nvm.sh"  # This loads nvm

# install & select latest node
nvm install node
nvm use node

echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "Done! Now close this terminal and open a new one to test node."
echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
