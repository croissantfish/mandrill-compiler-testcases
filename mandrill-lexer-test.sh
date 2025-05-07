#!/bin/bash

echo 'please modify the $names variable to be your own id'
names=$(cat list.txt) #modify to be your own id
echo $names
sleep 2
timeo=180s

function _SC() #safe call
{
    echo "[RUNNING] : $*"
    eval $*
    if [ $? -ne 0 ]; then
        echo "[ERROR] : command $* failed, please check, exiting..."
        exit
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
    echo now testing ${name}...
    _SC cd students
    if [ ! -d $name ]; then
        _SC mkdir $name "&&" cd $name
        _SC git clone "git@bitbucket.org:${name}/mandrill2025.git"
        _SC cd ..
    fi
    _SC cd $name/mandrill2025
    _SC git checkout -f main
    _SC git pull
    _SC git fetch --tags
    _SC git checkout -f lexer #pay attention to your tag! someone don't have the midterm tag
    _SC make clean #some one don't have make clean
    _SC make
    _SC cat ./lexervars.sh

    unset -v CCHK
    set -x
    source ./lexervars.sh #can't ensure SC here
    set +x
    echo CCHK=$CCHK

    _SC cd bin
    for filec in $(ls $normaldir/*.mds); do
#        filein=${filec%.mds}.in
        fileout=$stdlexoutdir/$(basename ${filec%.mds}).lexerout
        _SC cp $filec data.mds
        timeout $timeo $CCHK <data.mds 1>data.lexerout
#        if [ -f $filein ]; then
#            timeout $timeo spim -ldata 209715200 -lstack 104857600 -stat_file spimstat -file assem.s <$filein 1>spimout 2>/dev/null
#        else
#            timeout $timeo spim -ldata 209715200 -lstack 104857600 -stat_file spimstat -file assem.s 1>spimout 2>/dev/null
#        fi
        pure_file_name=$(basename $filec)
        pure_file_name=${pure_file_name%.mx}
        diff data.lexerout $fileout >$diff_result_dir/$pure_file_name
        full_score=$((full_score+1))
#        file_limit=${filec%.mx}.limit
#        if [ -f $file_limit ]; then
#            full_score=$((full_score+1))
#        fi
        if [ ! -s $diff_result_dir/$pure_file_name ]; then
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
            echo ${filec%.mx} : FAILED >>$log_file
            echo FAILED
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