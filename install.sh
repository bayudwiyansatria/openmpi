#!/bin/bash
echo "";

echo "################################################";
echo "##  Welcom To Bayu Dwiyan Satria Installation ##";
echo "################################################";

echo "";

echo "Use of code or any part of it is strictly prohibited.";
echo "File protected by copyright law and provided under license.";
echo "To Use any part of this code you need to get a writen approval from the code owner: bayudwiyansatria@gmail.com.";

echo "";

# User Access
if [ $(id -u) -eq 0 ]; then

    echo "################################################";
    echo "##        Checking System Compability         ##";
    echo "################################################";

    echo "";
    echo "Please wait! Checking System Compability";
    echo "";

    # Operation System Information
    if type lsb_release >/dev/null 2>&1 ; then
        os=$(lsb_release -i -s);
    elif [ -e /etc/os-release ] ; then
        os=$(awk -F= '$1 == "ID" {print $2}' /etc/os-release);
    elif [ -e /etc/os-release ] ; then
        os=$(awk -F= '$1 == "ID" {print $3}' /etc/os-release);
    else
        exit 1;
    fi

    os=$(printf '%s\n' "$os" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g');

    # Update OS Current Distribution
    read -p "Update Distro (y/n) [ENTER] (y)(Recommended): " update;
    update=$(printf '%s\n' "$update" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g');

    if [ "$update" == "y" ] ; then 
        if [ "$os" == "ubuntu" ] || [ "$os" == "debian" ] ; then
            apt-get -y update && apt-get -y upgrade;
        elif [ "$os" == "centos" ] || [ "$os" == "rhel" ] || [ "$os" == "fedora" ] ; then
            yum -y update && yum -y upgrade;
        else
            exit 1;
        fi
    fi

    # Required Packages
    if [ "$os" == "ubuntu" ] || [ "$os" == "debian" ] ; then
        apt-get -y install git && apt-get -y install wget;
    elif [ "$os" == "centos" ] || [ "$os" == "rhel" ] || [ "$os" == "fedora" ]; then
        yum -y install git && yum -y install wget;
    else
        exit 1;
    fi

    echo "";
    echo "################################################";
    echo "##             OpenMPI Installation           ##";
    echo "################################################";
    echo "";

    # Required Packages
    if [ "$os" == "ubuntu" ] || [ "$os" == "debian" ] ; then
        apt-get -y install openmpi-bin 
    elif [ "$os" == "centos" ] || [ "$os" == "rhel" ] || [ "$os" == "fedora" ]; then
        yum -y install openmpi
    else
        exit 1;
    fi

    echo "";
    echo "################################################";
    echo "##             OpenMPI Configuration          ##";
    echo "################################################";
    echo "";

    # Network Configuration

    interface=$(ip route | awk '/^default/ { print $5 }');
    ipaddr=$(ip -o -4 addr list "$interface" | awk '{print $4}' | cut -d/ -f1);
    gateway=$(ip route | awk '/^default/ { print $3 }');
    subnet=$(ip addr show "$interface" | grep "inet" | awk -F'[: ]+' '{ print $3 }' | head -1);
    network=$(ipcalc -n "$subnet" | cut -f2 -d= );
    prefix=$(ipcalc -p "$subnet" | cut -f2 -d= );
    hostname=$(echo "$HOSTNAME");
    master=$ipaddr;
    host=1;
    echo -e  ''$master' master # Master' >> /etc/hosts;


    echo "";
    echo "################################################";
    echo "##             Authorization                  ##";
    echo "################################################";
    echo "";

    echo "Setting up cluster authorization";
    echo "";

    username=$(whoami);

    if [[ -f "/home/$username/.ssh/id_rsa" && -f "/home/$username/.ssh/id_rsa.pub" ]]; then
        echo "SSH already setup";
        echo "";
    else
        echo "SSH setup";
        echo "";
        sudo -H -u $username bash -c 'ssh-keygen';
        echo "Generate SSH Success";
    fi

    if [ -e "/home/$username/.ssh/authorized_keys" ] ; then
        echo "Authorization already setup";
        echo "";
    else
        echo "Configuration authentication";
        echo "";
        sudo -H -u $username bash -c 'touch /home/'$username'/.ssh/authorized_keys';
        echo "Authentication Compelete";
        echo "";
    fi
    
    sudo -H -u $username bash -c 'cat /home/'$username'/.ssh/id_rsa.pub >> /home/'$username'/.ssh/authorized_keys';
    chown -R $username:$username "/home/$username/.ssh/";
    sudo -H -u $username bash -c 'chmod 600 /home/'$username'/.ssh/authorized_keys';

    # Firewall
    echo "################################################";
    echo "##            Firewall Configuration          ##";
    echo "################################################";
    echo "";

    echo "Disabling Firewall";

    if [ "$os" == "ubuntu" ] || [ "$os" == "debian" ] ; then
        echo "Disabling Firewall Services";
        systemctl stop ufw && systemctl disable ufw;

    elif [ "$os" == "centos" ] || [ "$os" == "rhel" ] || [ "$os" == "fedora" ] ; then 
        echo "Enable Firewall Services";
        echo "";
        systemctl stop firewalld;
        systemctl disable firewalld;
    else
        exit 1;
    fi
    
    if [ "$master" == "n" ] ; then 
        echo "Your worker already setup";
    else
        echo "";
        echo "############################################";
        echo "##        Adding Worker Nodes             ##";
        echo "############################################";
        echo "";

        read -p "Do you want to setup worker? (y/N) [ENTER] (n) " workeraccept;
        workeraccept=$(printf '%s\n' "$workeraccept" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g');

        if [ -n "$workeraccept" ] ; then 
            if [ "$workeraccept" == "y" ] ; then 
                while [ "$workeraccept" == "y" ] ; do 
                    read -p "Please enter worker IP Address [ENTER] " worker;
                    echo -e  ''$worker' worker'$host' # Worker' >> /etc/hosts;
                    if [[ -f "~/.ssh/id_rsa" && -f "~/.ssh/id_rsa.pub" ]]; then 
                        echo "SSH already setup";
                        echo "";
                    else
                        echo "SSH setup";
                        echo "";
                        ssh-keygen;
                        echo "Generate SSH Success";
                    fi

                    if [ -e "~/.ssh/authorized_keys" ] ; then 
                        echo "Authorization already setup";
                        echo "";
                    else
                        echo "Configuration authentication";
                        echo "";
                        touch ~/.ssh/authorized_keys;
                        echo "Authentication Compelete";
                        echo "";
                    fi
                    ssh-copy-id -i ~/.ssh/id_rsa.pub "$username@$ipaddr"
                    ssh-copy-id -i ~/.ssh/id_rsa.pub "$worker"

                    ssh $worker "wget https://raw.githubusercontent.com/bayudwiyansatria/OpenMPI-Environment/master/express-install.sh -O /tmp/express-install.sh";
                    ssh $worker "chmod 777 /tmp/express-install.sh";
                    ssh $worker "./tmp/express-install.sh" "$ipaddr";
                    scp /home/$username/.ssh/authorized_keys /home/$username/.ssh/id_rsa /home/$username/.ssh/id_rsa.pub $username@$worker:/home/$username/.ssh/
                    ssh $worker "chown -R $username:$username /home/$username/.ssh/";
                    ssh $worker "echo -e  ''$ipaddr' # Master' >> /etc/hosts";
                    read -p "Do you want to add more worker? (y/N) [ENTER] (n) " workeraccept;
                    workeraccept=$(printf '%s\n' "$workeraccept" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g'); 
                done
            fi
        fi

        echo "Worker added";
    fi

    echo "";
    echo "############################################";
    echo "##                Cleaning                ##";
    echo "############################################";
    echo "";

    echo "Cleaning Installation Packages";

    history -c && history -w
    rm -rf /tmp/install.sh

    echo "Success Installation Packages";

    echo "";
    echo "############################################";
    echo "## Thank You For Using Bayu Dwiyan Satria ##";
    echo "############################################";
    echo "";
    
    echo "Installing OpenMP Successfully";
    echo "";

    echo "User $username";
    echo "";

    echo "Author    : Bayu Dwiyan Satria";
    echo "Email     : bayudwiyansatria@gmail.com";
    echo "Feel free to contact us";
    echo "";

    read -p "Do you want to reboot? (y/N) [ENTER] [n] : "  reboot;
    if [ -n "$reboot" ] ; then
        if [ "$reboot" == "y" ]; then
            reboot;
        else
            echo "We highly recomended to reboot your system";
        fi
    else
        echo "We highly recomended to reboot your system";
    fi

else
    echo "Only root may can install to the system";
    exit 1;
fi