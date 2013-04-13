#!/bin/bash

#find images and start and end times in FCP project file

set -u
set -e
set -x


projectfile="GENEVA_MUSIC_CUES_ONLY.xml"

echo "audiotrack start end duration" > audiosummary.txt


prevstart=0
prevend=0

grep "<clipitem id=" "${projectfile}" | while read line; do

    imageinfo=$(grep -A 10 "${line}" "${projectfile}" | tr -d "\n\t " )
    #echo "line: ${line}"

    #imagename=$( echo "${line}" | sed 's/\<clipitem id=\"\(.*\)\"\>/\1/' | tr " " "_")
    imagename=$( echo "${line}" | sed 's/\<clipitem id=\"\(.*\)\"\>/\1/')
    #echo "imagename: ${imagename}"

    extension="${imagename##*.}"

    #if [[  x${extension:+set} = "xset" && ( ${#extension} < 6 ) ]]; then 
    if [ ${#extension} -lt 6 ]; then 
    start=$(echo $imageinfo | sed 's/.*\<start\>\(.*\)\<\/start\>.*/\1/')

    #echo "start: ${start}"
    end=$(echo $imageinfo | sed 's/.*\<end\>\(.*\)\<\/end\>.*/\1/')
    #echo "end: ${end}"

    in=$(echo $imageinfo | sed 's/.*\<in\>\(.*\)\<\/in\>.*/\1/')
    #echo "in: ${in}"
    out=$(echo $imageinfo | sed 's/.*\<out\>\(.*\)\<\/out\>.*/\1/')
    #echo "out: ${out}"

    duration=$(echo "${out} - ${in}" | bc)
    #echo "duration: ${duration}"


	#a transitional item leads into the clip.  need to extract transitions start time
    if [ ${start} -eq -1 ]; then
        #get the 15 lines preceding the image name - this should get the transitional item
        #strip off new lines and tabs
        precedingTransition=$(grep -B 15 "<clipitem id=\"${imagename}\">" "${projectfile}" | tr -d "\n\t " )
        start=$(echo "${precedingTransition}" | sed 's/.*\<start\>\(.*\)\<\/start\>.*/\1/')
        echo "${imagename} ${start}" >> transitionalaudiotracks.txt
        #start=$(echo "${prevend} + ${duration}" | bc)
    fi

    if [ ${end} -eq -1 ]; then
        end=$(echo "${start} + ${duration}" | bc)
    fi

    prevstart=${start}
    prevend=${end}
    startseconds=$(echo "( ${start} / 30 ) % 60" | bc)
    startframes=$(echo "${start} % 30" | bc)
    startminutes=$(echo "${start} / ( 30 * 60 )" | bc)
    endseconds=$(echo "( ${end} / 30 ) % 60" | bc)
    endframes=$(echo "${end} % 30" | bc)
    endminutes=$(echo "${end} / ( 30 * 60 )" | bc)

	durseconds=$(echo "( ${duration} / 30 ) % 60" | bc)
    durframes=$(echo "${duration} % 30" | bc)
    durminutes=$(echo "${duration} / ( 30 * 60 )" | bc)

	
	
    if [ ${#startminutes} -eq 1 ]; then
        startminutes=0${startminutes}
    fi
    if [ ${#startseconds} -eq 1 ]; then
        startseconds=0${startseconds}
    fi
    if [ ${#startframes} -eq 1 ]; then
        startframes=0${startframes}
    fi

    if [ ${#endminutes} -eq 1 ]; then
        endminutes=0${endminutes}
    fi
    if [ ${#endseconds} -eq 1 ]; then
        endseconds=0${endseconds}
    fi
    if [ ${#endframes} -eq 1 ]; then
        endframes=0${endframes}
    fi
    
    if [ ${#durminutes} -eq 1 ]; then
        durminutes=0${durminutes}
    fi
    if [ ${#durseconds} -eq 1 ]; then
        durseconds=0${durseconds}
    fi
    if [ ${#durframes} -eq 1 ]; then
        durframes=0${durframes}
    fi
    
    imagename=$(echo "${imagename}"| tr " " "_")

    #echo -e  "${imagename},${startminutes}:${startseconds}:${startframes},${endminutes}:${endseconds}:${endframes}"
    echo -e  "${imagename}\t${startminutes}:${startseconds}:${startframes}\t${endminutes}:${endseconds}:${endframes}\t${durminutes}:${durseconds}:${durframes}" >> audiosummary.txt
    fi
done
echo "" > audio_tracks.txt
column -t audiosummary.txt >> audio_tracks.txt
