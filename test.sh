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

git clone https://github.com/bayudwiyansatria/Library-MPI.git;

mpicc Library-MPI/main.c
mpirun -np2 -hosts master,worker1,worker2 Library-MPI/a.out ./mm -n 10240 -t