#!/bin/bash

echo 'please modify the $names variable to be your own id'
names=$(cat list.txt) #modify to be your own id
echo $names
sleep 2
timeo=10s

function _SC() #safe call
{
    printf "[RUNNING] : %s\n" "$*"
    eval $*
    if [ $? -ne 0 ]; then
        echo "[ERROR] : command $* failed, please check, exiting..."
        exit 1
    fi
}

outdir=$(pwd)
mkdir -p students
for name in ${names[@]}; do
    cd $outdir || exit 1
    echo "####################################################"
    echo "# Student account: ${name}"
    echo "####################################################"
    _SC cd students
    if [ ! -d $name ]; then
        _SC mkdir $name
    fi
    if [ ! -d $name/mandrill2025 ]; then
        _SC cd $name
        (_SC git clone "git@bitbucket.org:${name}/mandrill2025.git") || (_SC git clone "git@bitbucket.org:${name}/mandrill2025.git") || (_SC git clone "git@bitbucket.org:${name}/mandrill2025.git") || { echo "[ERROR] cannot clone code, goto next student..."; echo $name "0/-8" >>$statistics; continue; }
        _SC cd ..
    fi
    cd $outdir || exit 1
done
