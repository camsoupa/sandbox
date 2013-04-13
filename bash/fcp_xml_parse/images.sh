#!/bin/bash

#find images and start and end times in FCP project file

#set -u
#set -e
#set -x


projectfile=$1
imagelist=$2


echo "image  start  end  duration" > imagesummary.txt

cat ${imagelist} | while read line; do
imageinfo=$(grep -A 10 "${line}" ${projectfile} | tr -d "\n\t " )
echo "line: ${line}"
imagename=$( echo "${line}" | sed 's/\<clipitem id=\"\(.*\)\"\>/\1/')
echo "imagename: ${imagename}"
start=$(echo $imageinfo | sed 's/.*\<start\>\(.*\)\<\/start\>.*/\1/')
echo "start: ${start}"
end=$(echo $imageinfo | sed 's/.*\<end\>\(.*\)\<\/end\>.*/\1/')
echo "end: ${end}"
duration=$(echo $imageinfo | sed 's/.*\<duration\>\(.*\)\<\/duration\>.*/\1/')
echo "duration: ${duration}"


echo "${imagename} ${start}  ${end} ${duration}" >> imagesummary.txt

done