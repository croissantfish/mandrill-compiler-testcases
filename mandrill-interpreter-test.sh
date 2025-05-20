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

if [ ! -d mandrill-compiler-testcases ]; then
    _SC git clone git@github.com:croissantfish/mandrill-compiler-testcases.git
fi

_SC cd mandrill-compiler-testcases
_SC git pull
(_SC git checkout interpreter) || { echo "[WARNING] Cannot find specific branch, use main branch for test."; }
_SC cd ..

normaldir=$(pwd)/mandrill-compiler-testcases/mandrill-src
inputdir=$(pwd)/mandrill-compiler-testcases/mandrill-in
ansdir=$(pwd)/mandrill-compiler-testcases/mandrill-ans
resdir=$(pwd)/results
mkdir -p $resdir
statistics=$resdir/statistics
#rm -rf $statistics

for name in ${names[@]}; do
    cd $outdir || exit 1
    diff_result_dir=$resdir/diff_result_$name
    rm -rf $diff_result_dir
    mkdir -p $diff_result_dir
    log_file=$resdir/${name}.LOG
    rm -rf $log_file
    score=0
    full_score=0
    echo "####################################################"
    echo "# Student account: ${name}"
    echo "####################################################"
    _SC cd students
    if [ ! -d $name ]; then
        _SC mkdir $name
    fi
    if [ ! -d $name/mandrill2025 ]; then
        _SC cd $name
        (_SC git clone "git@bitbucket.org:${name}/mandrill2025.git") || { echo "[ERROR] cannot clone code, goto next student..."; echo $name "0/-8" >>$statistics; continue; }
         _SC cd ..
    fi
    _SC cd $name/mandrill2025
    (_SC git checkout -f main) || { echo "[ERROR] cannot checkout the main, goto next student..."; echo $name "0/-7" >>$statistics; continue; }
    (_SC git pull) || { echo "[ERROR] cannot update student code, goto next student..."; echo $name "0/-6" >>$statistics; continue; }
    _SC git fetch -f --tags
    (_SC git checkout -f interpreter) || { echo "[ERROR] cannot checkout interpreter tag, goto next student..."; echo $name "0/-5" >>$statistics; continue; }
    (_SC make clean) || { echo "[ERROR] clean previous build failed, goto next student..."; echo $name "0/-4" >>$statistics; continue; }
    (_SC make) || { echo "[ERROR] compiling student code failed, goto next student..."; echo $name "0/-3" >>$statistics; continue; }
    (_SC cat ./interpretervars.sh) || { echo "[ERROR] file to set CCHK is not existed, goto next student..."; echo $name "0/-2" >>$statistics; continue; }

    unset -v CCHK
    set -x
    source ./interpretervars.sh #can't ensure SC here
    set +x
    echo CCHK=$CCHK
    echo CCHK=$CCHK >>$log_file

    if [ ! -d bin ]; then
        echo "[ERROR] make did not create bin directory, goto next student..."
        echo $name "0/-1" >>$statistics
        continue
    fi
    _SC cd bin
    for filec in $normaldir/*.mds; do
        full_score=$((full_score+1))
        fileans=$ansdir/$(basename ${filec%.mds}).ans
        filein=$inputdir/$(basename ${filec%.mds}).in
        _SC cp $filec data.mds
        _SC cp $filein mandrill.in
        echo "[RUNNING] timeout $timeo $CCHK <data.mds 1>data.out"
        timeout $timeo $CCHK <data.mds 1>data.out
        returncode=$?
        if [ $returncode -ne 0 ]; then
            echo "FAILED: Time Limit Exceeded or Runtime Error, return code: $returncode"
            echo ${filec%.mds} : FAILED >>$log_file
            continue
        fi
        pure_file_name=$(basename $filec)
        pure_file_name=${pure_file_name%.mds}
        diff data.out $fileans >$diff_result_dir/$pure_file_name.out.diff.txt
        if [ ! -s $diff_result_dir/$pure_file_name.out.diff.txt ]; then
            echo PASSED
            score=$((score+1))
        else
            echo ${filec%.mds} : FAILED >>$log_file
            echo "FAILED: WRONG ANSWER, Please check $diff_result_dir/$pure_file_name.out.diff.txt."
        fi
    done

    echo count: $score/$full_score >>$log_file
    echo count: $score/$full_score
    echo $name $score/$full_score >>$statistics
    _SC cd ..
    _SC git checkout -f main
    cd $outdir || exit 1
done

cd $outdir || exit 1
_SC cd mandrill-compiler-testcases
_SC git checkout -f main
cd $outdir || exit 1
