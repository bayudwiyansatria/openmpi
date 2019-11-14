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

echo "################################################";
echo "##                MPI TES                     ##";
echo "################################################";

echo "Get username ";
username=$(whoami);

echo "Exec by : $username";

echo "Clone sample application to /home/$username/Library-MPI";
git clone https://github.com/bayudwiyansatria/Library-MPI.git /home/$username/Library-MPI;
echo "Clone Success";

echo "Distribute to worker";
scp -r /home/$username/Library-MPI worker1:/home/$username/
scp -r /home/$username/Library-MPI worker2:/home/$username/
echo "Distribution complete";

echo "MPI Compile /home/$username/Library-MPI/main.c";
mpicc /home/$username/Library-MPI/main.c;

echo "MPI Run /home/$username/Library-MPI/main.c";
mpirun -np2 -hosts master,worker1,worker2 /home/$username/Library-MPI/a.out ./mm -n 10240 -t
echo "Testing complete";

echo "";
echo "############################################";
echo "## Thank You For Using Bayu Dwiyan Satria ##";
echo "############################################";
echo "";

echo "Author    : Bayu Dwiyan Satria";
echo "Email     : bayudwiyansatria@gmail.com";
echo "Feel free to contact us";
echo "";

read -p "Do you want to clean app? (y/N) [ENTER] [n] : "  clean;
if [ -n "$clean" ] ; then
    if [ "$clean" == "y" ]; then
        rm -rf /home/$username/Library-MPI;
        ssh worker1 "rm -rf /home/$username/Library-MPI";
        ssh worker2 "rm -rf /home/$username/Library-MPI";
    else
        echo "Application still exist at /home/$username/Library-MPI";
    fi
else
    echo "Application still exist at /home/$username/Library-MPI";
fi