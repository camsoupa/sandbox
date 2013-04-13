#!/bin/bash

#set -e
#set -u
#set -x

tests=0
fails=0

echo "" > no_prints
echo "" > failures
echo "" > expects_errors

for file in tests/*.py.hir
do 
  #printf "%s\n" "Testing: $i"
  i=${file//.hir}
  
  racket pydesugar_rkt.zo < $i.hir > $i.lir
  racket pydesugar.rkt < $i.hir > $i.lir.actual     
  
  #desugar
  
  cat lir-header.rkt $i.lir > $i.lir.rkt
  cat lir-header.rkt $i.lir.actual > $i.lir.actual.rkt

  racket $i.lir.rkt > $i.lir.answer.expected
  racket $i.lir.actual.rkt> $i.lir.answer.actual

  diff $i.lir.answer.expected $i.lir.answer.actual

  #cps

  racket pycps_rkt.zo < $i.lir > $i.cps
  racket pycps.rkt < $i.lir.actual > $i.cps.actual  

  cat cps-header.rkt $i.cps > $i.cps.rkt
  cat cps-header.rkt $i.cps.actual > $i.cps.actual.rkt
  
  racket $i.cps.rkt > $i.cps.answer.expected
  racket $i.cps.actual.rkt> $i.cps.answer.actual
      
  result=`diff -q $i.cps.answer.expected $i.cps.answer.actual`

  answers_differ=0
  if $(echo "${result}" | grep -q differ); then
    answers_differ=1
  fi

  actual_has_error=0
  if $(grep -q "context..." "${i}.cps"); then
    actual_has_error=1
  fi
  
  expected_error=1
  if [ -s  "${i}.cps" ]; then
    expected_error=0
  else  
    echo "${i}" >> expects_errors
  fi

  tests=$(expr $tests + 1)

  if [ -s "${i}.cps.answer.expected" ]; then
    echo "${i}" >> has_prints
  else
    echo "${i}" >> no_prints
  fi

  if [[ $answers_differ -eq 1 || $actual_has_error -eq 1 ]]; then
    
     if [[ $expected_error -eq 1 && $actual_has_error == $expected_error ]]
     then
       echo -e "\033[32mPASS ... ${i} (expected ERROR) \033[0m";
     else
       echo -e "\033[31mFAIL ... ${i} (see ${i}.diff)\033[0m";
       #diff --left-column -y $i.expected.answer $i.actual.answer > $i.answer.diff
       #diff --left-column -y $i.hir $i.actual > $i.diff
       echo $i >> failures
       fails=$(expr $fails + 1)
     fi
  else
     echo -e "\033[32mPASS ... ${i}\033[0m";
  fi

done

echo $fails / $tests

