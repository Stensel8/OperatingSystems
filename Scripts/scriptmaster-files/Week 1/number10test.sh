#!/bin/bash

########################################################################################
# © Sten Tijhuis - 550600
# number10test.sh
########################################################################################

echo -n "Enter a number: "
read VAR

if [[ $VAR -gt 10 ]]
then
   echo "The variable is greater than 10."
else
   echo "The variable is less or equal than 10."
fi
