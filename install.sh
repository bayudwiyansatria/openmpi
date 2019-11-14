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
        apt-get -y install openmpi-bin nfs-kernel-server nfs-common htop
    elif [ "$os" == "centos" ] || [ "$os" == "rhel" ] || [ "$os" == "fedora" ]; then
        yum -y install openmpi nfs-kernel-server nfs-common htop
    else
        exit 1;
    fi

    # User Generator
    read -p "Do you want to create user for MPI administrator? (y/N) [ENTER] (y) " createuser;
    createuser=$(printf '%s\n' "$createuser" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g');

    if [ -n createuser ] ; then
        if [ "$createuser" == "y" ] ; then
            read -p "Enter username : " username;
            read -s -p "Enter password : " password;
            egrep "^$username" /etc/passwd >/dev/null;
            if [ $? -eq 0 ]; then
                echo "$username exists!"
            else
                pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
                useradd -m -p $pass $username
                [ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
            fi
            usermod -aG $username $password;
        else
            read -p "Do you want to use exisiting user for MPI administrator? (y/N) [ENTER] (y) " existinguser;
            if [ "$existinguser" == "y" ] ; then
                read -p "Enter username : " username;
                egrep "^$username" /etc/passwd >/dev/null;
                if [ $? -eq 0 ]; then
                    echo "$username | OK" ;
                else
                    echo "Username isn't exist we use root instead";
                    username=$(whoami);
                fi 
            else 
                username=$(whoami);
            fi
        fi
    else
        read -p "Enter username : " username;
        read -s -p "Enter password : " password;
        egrep "^$username" /etc/passwd >/dev/null;
        if [ $? -eq 0 ]; then
            echo "$username exists!"
        else
            pass=$(perl -e 'print crypt($ARGV[0], "password")' $password)
            useradd -m -p $pass $username
            [ $? -eq 0 ] && echo "User has been added to system!" || echo "Failed to add a user!"
            usermod -aG $username $password;
            echo "User $username created successfully";
            echo "";
        fi
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

    # Setup Sharing Directory
    mkdir -p /home/$username/share;
    echo -e "/home/$username/share *(rw,sync,no_root_squash,no_subtree_check)" >> /etc/exports;

    exportfs -a;
    service nfs-kernel-server restart;

    # Permanent Setup NFS
    echo -e "$master:/home/$username/share /home/$username/share nfs" >> /etc/fstab;

    echo "";
    echo "################################################";
    echo "##             Authorization                  ##";
    echo "################################################";
    echo "";

    echo "Setting up cluster authorization";
    echo "";


    if [[ -f "/home/$username/.ssh/id_rsa" && -f "/home/$username/.ssh/id_rsa.pub" ]]; then
        echo "SSH already setup for $username";
        echo "";
    else
        echo "SSH setup for $username";
        echo "";
        sudo -H -u $username bash -c 'ssh-keygen';
        echo "Generate SSH Success";
    fi

    if [ -e "/home/$username/.ssh/authorized_keys" ] ; then
        echo "Authorization already setup";
        echo "";
    else
        echo "Configuration authentication for $username";
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
        workers=();
        workers[0]=$master;
        if [ -n "$workeraccept" ] ; then 
            if [ "$workeraccept" == "y" ] ; then 
                while [ "$workeraccept" == "y" ] ; do 
                    read -p "Please enter worker IP Address [ENTER] " worker;
                    workers[$host]=$worker;
                    if [[ -f "~/.ssh/id_rsa" && -f "~/.ssh/id_rsa.pub" ]]; then 
                        echo "SSH already setup for root@$ipaddr";
                        echo "";
                    else
                        echo "SSH setup for root@$ipaddr";
                        echo "";
                        ssh-keygen;
                        echo "Generate SSH Success";
                    fi

                    if [ -e "~/.ssh/authorized_keys" ] ; then 
                        echo "Authorization already setup for root@$ipaddr";
                        echo "";
                    else
                        echo "Configuration authentication for root@$ipaddr";
                        echo "";
                        touch ~/.ssh/authorized_keys;
                        echo "Authentication Compelete for root@$ipaddr";
                        echo "";
                    fi
                    
                    echo "Authenticate setup for $username@$ipaddr";
                    ssh-copy-id -i ~/.ssh/id_rsa.pub "$username@$ipaddr"

                    echo "Authenticate setup for $worker";
                    ssh-copy-id -i ~/.ssh/id_rsa.pub "$worker"

                    # Installation On Worker Machine
                    ssh $worker "wget https://raw.githubusercontent.com/bayudwiyansatria/OpenMPI-Environment/master/express-install.sh -O /tmp/express-install.sh";
                    ssh $worker "chmod 777 /tmp/express-install.sh";
                    ssh $worker "/tmp/express-install.sh" "$ipaddr" "$username" "$password";

                    # Send Authorization Key To Worker Machine
                    scp /home/$username/.ssh/authorized_keys /home/$username/.ssh/id_rsa /home/$username/.ssh/id_rsa.pub $username@$worker:/home/$username/.ssh/
                    ssh $worker "chown -R $username:$username /home/$username/.ssh/";

                    # New Worker
                    read -p "Do you want to add more worker? (y/N) [ENTER] (n) " workeraccept;
                    workeraccept=$(printf '%s\n' "$workeraccept" | LC_ALL=C tr '[:upper:]' '[:lower:]' | sed 's/"//g'); 
                done
            fi
        fi

        for worker in "${workers[@]}" ; do 
            echo -e  ''$worker' worker'$host' # Worker' >> /etc/hosts;
            ssh $worker "echo -e $worker worker'$host' # Worker'$host' >> /etc/hosts";
            host=$(( $host + 1 ));
        done

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
    echo "Password $password";

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