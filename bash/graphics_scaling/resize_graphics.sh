#!/bin/bash

# generates scaled graphics and .atl, .road and realrect.bound files from full size graphics and associated metadata

# USAGE: <target-Screen-Width> <target-Screen-Height> <src-dir> <dest-dir>

# depends on resize.data metadata files  and .road (if any) metadata file(s) in src dir

# METADATA LINE FORMAT in resize.data file
# <glob=filename_glob>:<atl=atlas_group_name>:<resize=resize_param>[:alternates=<alternate_set_name>][:compression=yes][,compression param 01][,compression param 02],...[:realrect=filename,left bound,top bound,right bound,bottom bound, scale factor X, scale factor Y]

# ALTERNATES
# some files have alternate source graphics for different aspect ratios.  Alternates should be named with a letter underscore prefix such as 'A_'
# Each alternate set has a an <alternate_set_name> to designate the set of files from which a choice will be made.

# EXAMPLE
# since the iPhone4 resolution is 960h x 640w, the script could be called using the following command:
# $./resizeAssets.sh 640 960 ./graphics/ginormous ./graphics/wvga 

# FUNCTIONS 
# usage()		--- called by main()
# processAlternates()	--- called by resizeGraphics()
# resizeGraphics()	--- called by main()
# main()

set -u #referencing undefined variable causes error
set -x #print out everything it does
set -e #anything with non-zero exit status aborts script

usage()
{
	echo "USAGE: <target-Screen-Width> <target-Screen-Height> <src-dir> <dest-dir>"
	exit 1
}

#select from alternates stored in *.alternate.tmp files
#each alternate set will have a different .alternate.tmp file associated with it
processAlternates()
{
	targetWidth=${1}
	targetHeight=${2}
	outDir="${3}"

	find . -type f -name '*.alternates.tmp' | while read alternateFile; do

		currDir=$(dirname ${alternateFile})
	
		cat ${alternateFile} | while read alternate; do
	
			altglob=$( echo "${alternate}" | cut -s -d: -f1  | cut -s -d= -f2)
			targetAspect=$(echo "scale=12; ${targetWidth} / ${targetHeight}" | bc )

			#calculate difference between target aspect ratio and current alternate possibility's aspect
			imageWidth=$(convert "${currDir}/${altglob}" -format %w info:)
			imageHeight=$(convert "${currDir}/${altglob}" -format %h info:)
			imageAspect=$(echo "scale=12;  ${imageWidth} / ${imageHeight}" | bc )
			difference=$(echo "scale=12; ${imageAspect} - ${targetAspect}" | bc )
			absoluteDifference=${difference#-}
			
			#append difference field and add the new alternate possibility to the file
			echo ${absoluteDifference}:${alternate} >> ${currDir}/alternates.ratios.tmp
			#sort lines in file so that closest ratio to target aspect ratio is at the top
			sort -n -t ':' -k 1 ${currDir}/alternates.ratios.tmp
			#pull out the closest option
			closest=$(head -n 1 ${currDir}/alternates.ratios.tmp)
			#save only the closest option
			echo ${closest} > "${currDir}/alternates.ratios.tmp"
		done
	
		#extract data of the closest match to the target aspect ratio
		cat "${currDir}/alternates.ratios.tmp" | tr ':' '\n'  > "${currDir}/closest.alternate.tmp"
		closestGlob=$(grep 'glob=' ${currDir}/closest.alternate.tmp  | cut -s -d= -f2)
		closestAtl=$(grep 'atl=' ${currDir}/closest.alternate.tmp  | cut -s -d= -f2)
		closestResize=$(grep 'resize=' ${currDir}/closest.alternate.tmp  | cut -s -d= -f2)
		closestWidth=$(echo "${targetWidth} * ${closestResize}" | bc)
		
		rm ${currDir}/alternates.ratios.tmp
		rm ${currDir}/closest.alternate.tmp
		
		#now that the appropriate alternate is selected from the choices, process that image or image sequence (if an animation)
		find "${currDir}" -type f -name "${closestGlob}" | while read image; do
			outputName="$(basename ${image})"
			#strip off alternate's letter-underscore prefix so that resized-dir receives a predictable filename from any of the alternate options
			outputName="${outputName#??}"
			convert "${image}" -define png:color-type=6 -resize ${closestWidth} "${outDir}/${outputName}"
			echo $(basename "${outputName}") >> "${outDir}/${closestAtl}.atl"
		done
	
		rm "${alternateFile}"
	done
}

resizeGraphics()
{
	targetWidth=$1
	targetHeight=$2
	fullSizeDir="${3}"
	outDir="${4}"
	 
	#initialize realrect.bound file with a header
	#realrect.bound is a file ised to overrides collision information for animations that do not fill their own frame for the duration of the animation
	# i.e. - so that you don't destroy an obstacle merely by riding past it.
	echo "<name> <left> <top> <right> <bottom> <x scale factor> <y scale factor>" > "${outDir}/realrect.bound"


	find "${fullSizeDir}" -type f -name 'resize.data' | while read filename; do
		cat ${filename} | while read line; do
		
			resizeDir=$(dirname ${filename})
		
			if [ x${line:+set} = xset ]; then
			
				newLine=$(echo ${line} | tr ':' '\n')
			
				echo "${newLine}" > ${resizeDir}/resize.tmp

				glob=$(grep 'glob=' "${resizeDir}/resize.tmp"  | cut -s -d= -f2)
				atlas=$(grep 'atl=' "${resizeDir}/resize.tmp" | cut -s -d= -f2)
				resize=$(grep 'resize=' "${resizeDir}/resize.tmp" | cut -s -d= -f2)
				compression=$(grep 'compression=' "${resizeDir}/resize.tmp" | cut -s -d= -f2)
				alternates=$(grep 'alternates=' "${resizeDir}/resize.tmp" | cut -s -d= -f2)
				realrect=$(grep 'realrect=' "${resizeDir}/resize.tmp" | cut -s -d= -f2)
			
				rm ${resizeDir}/resize.tmp
			
				#compress.tmp stores names of files requiring compression before sprite sheet generation
				if ! grep "${atlas}" "${outDir}/compress.tmp" > /dev/null 2>&1; then
					echo "${atlas}:compression=${compression:-no}" >> "${outDir}/compress.tmp"
				fi
				
				#if a specific target size in form <width>x<height> is specified, these variables will be set
				absoluteX=$(echo ${resize} | cut -s -dx -f1)
				absoluteY=$(echo ${resize} | cut -s -dx -f2)

				#alternates stored to be processed later - alternate sets should not span multiple resize.data files
				if [ x${alternates:+set} = xset ]; then
					echo "${line}" >> "${resizeDir}/${alternates}.alternates.tmp"
				else
					#if absolute <width>x<height> target size specified (can be aspect ratio destructive)
					if [ x${absoluteY:+set} = xset ]; then
						find "${resizeDir}" -type f -name "${glob}" | while read absoluteFile; do
							convert "${absoluteFile}" -define png:color-type=6 -resize "${absoluteX}x${absoluteY}!" "${outDir}/$(basename ${absoluteFile})"
						done
					else
					#else target ratio to screen-size specified
						width=$(echo "scale=12; ${targetWidth} * ${resize}" | bc | xargs printf "%1.0f")
						find "${resizeDir}" -type f -name "${glob}" | while read ratioFile; do
							convert "${ratioFile}" -define png:color-type=6 -resize ${width} "${outDir}/$(basename ${ratioFile})"
							echo "$(basename ${ratioFile})" >> "${outDir}/${atlas}.atl"
						done
					fi
					
					#ENGINE SPECIFIC FILES NEEDING TO BE SCALED WITH IMAGE(S)
					#road files are for determining road borders in game
					#if .road files exist, they need to be scaled to match the newly scaled image files to which they correspond
					#roadFilesExist=$(find ${resizeDir} -type f -name ${glob%.png}.road)
					#if [ x${roadFilesExist:+set} = xset ]; then
					#	./scaleRoadBounds.sh "${glob}" ${resize} ${targetWidth} ${targetHeight} "${resizeDir}" "${outDir}"  
					#fi
					
					#ENGINE SPECIFIC FILES NEEDING TO BE SCALED WITH IMAGE(S)
					#the realrect.bounds file is used to override collision data
					#if the current image has realrect data, scale it			
					#if [ x${realrect:+set} = xset ]; then				
					#	./scaleRealRect.sh "${realrect}" ${resize} ${targetWidth} ${targetHeight} "${resizeDir}" "${outDir}" 
					#fi
				fi
			
			fi
		done
	done
	
	#now that the main resizing process is over, alternate.tmp files will have been generated for any alternate sets
	processAlternates ${targetWidth} ${targetHeight} "${outDir}"
}

main()
{
	if [ $# != 4 ]
	then
		usage
	fi

	targetScreenWidth=$1
	targetScreenHeight=$2
	srcDir="${3}"
	destDir="${4}"
	
	if [ ! -d "${srcDir}" ]; then
		echo "source directory does not exist: ${srcDir}"
		exit 1	
	fi
	
	#WARNING: specify destination directory carefully - this script will destroy it!
	if [ -d "${destDir}" ]; then
		rm -rf "${destDir}"
	fi

	mkdir -p "${destDir}"
	
	resizeGraphics ${targetScreenWidth} ${targetScreenHeight} "${srcDir}" "${destDir}"
}

main ${@}
