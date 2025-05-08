#!/bin/bash

echo 'please modify the $names variable to be your own id'
names=$(cat list.txt) #modify to be your own id
echo $names
sleep 2
timeo=180s

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
else
    _SC cd mandrill-compiler-testcases
    _SC git pull
    _SC cd ..
fi

normaldir=$(pwd)/mandrill-compiler-testcases/mandrill-src
stdlexoutdir=$(pwd)/mandrill-compiler-testcases/mandrill-lexerout
resdir=$(pwd)/results
mkdir -p $resdir
statistics=$resdir/statistics
#rm -rf $statistics

for name in ${names[@]}; do
    cd $outdir
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
    (_SC git checkout -f lexer) || { echo "[ERROR] cannot checkout lexer tag, goto next student..."; echo $name "0/-5" >>$statistics; continue; }
    (_SC make clean) || { echo "[ERROR] clean previous build failed, goto next student..."; echo $name "0/-4" >>$statistics; continue; }
    (_SC make) || { echo "[ERROR] compiling student code failed, goto next student..."; echo $name "0/-3" >>$statistics; continue; }
    (_SC cat ./lexervars.sh) || { echo "[ERROR] file to set CCHK is not existed, goto next student..."; echo $name "0/-2" >>$statistics; continue; }

    unset -v CCHK
    set -x
    source ./lexervars.sh #can't ensure SC here
    set +x
    echo CCHK=$CCHK
    echo CCHK=$CCHK >>$log_file

    if [ ! -d bin ]; then
        echo "[ERROR] make did not create bin directory, goto next student..."
        echo $name "0/-1" >>$statistics
        continue
    fi
    _SC cd bin
    for filec in $(ls $normaldir/*.mds); do
#        filein=${filec%.mds}.in
        full_score=$((full_score+1))
        fileout=$stdlexoutdir/$(basename ${filec%.mds}).lexerout
        _SC cp $filec data.mds
        echo "[RUNNING] timeout $timeo $CCHK <data.mds 1>data.lexerout"
        timeout $timeo $CCHK <data.mds 1>data.lexerout
        if [ $? -ne 0 ]; then
            echo "FAILED: Time Limit Exceeded or Runtime Error"
            echo ${filec%.mds} : FAILED >>$log_file
            continue
        fi
#        if [ -f $filein ]; then
#            timeout $timeo spim -ldata 209715200 -lstack 104857600 -stat_file spimstat -file assem.s <$filein 1>spimout 2>/dev/null
#        else
#            timeout $timeo spim -ldata 209715200 -lstack 104857600 -stat_file spimstat -file assem.s 1>spimout 2>/dev/null
#        fi
        pure_file_name=$(basename $filec)
        pure_file_name=${pure_file_name%.mds}
        diff data.lexerout $fileout >$diff_result_dir/$pure_file_name.lexerout.diff.txt
#        file_limit=${filec%.mx}.limit
#        if [ -f $file_limit ]; then
#            full_score=$((full_score+1))
#        fi
        if [ ! -s $diff_result_dir/$pure_file_name ]; then
            echo PASSED
            score=$((score+1))
#            if [ -f $file_limit ]; then
#                num=-1
#                num=$(cat spimstat | awk ' { print $1 } ')
#                limit=$(cat $file_limit)
#                echo ${filec%.mx} : $num >>$log_file
#                echo NUMBER: $num / LIMIT: $limit
#                if [ $num -le $limit ]; then
#                    score=$((score+1))
#                fi
#            fi
        else
            echo ${filec%.mds} : FAILED >>$log_file
            echo "FAILED: WRONG ANSWER, Please check $diff_result_dir/$pure_file_name.lexerout.diff.txt."
        fi
        sleep 1
    done
    echo count: $score/$full_score >>$log_file
    echo count: $score/$full_score
    echo $name $score/$full_score >>$statistics
    _SC cd ..
    _SC git checkout -f main
    cd $outdir
done
