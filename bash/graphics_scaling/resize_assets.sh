#!/bin/bash

# generates scaled graphics and .atl, .road and realrect.bound files from full size graphics and associated metadata

# USAGE: <target-Screen-Width> <target-Screen-Height> <fullsize-src-dir> <resized-dest-dir>

# depends on resize.data and .road (if any) metadata file(s) in src dir

# METADATA LINE FORMAT in resize.data file
# <glob=filename_glob>:<atl=atlas_group_name>:<resize=resize_param>[:alternates=<alternate_set_name>][:compression=yes][,compression param 01][,compression param 02],...[:realrect=filename,left bound,top bound,right bound,bottom bound, scale factor X, scale factor Y]

# ALTERNATES
# some files have alternate source graphics for different aspect ratios.  Alternates should be named with a letter underscore prefix such as 'A_'
# Each alternate set has a an <alternate_set_name> to designate the set of files from which a choice will be made.

# EXAMPLE
# since the iPhone4 resolution is 960h x 640w, the script could be called using the following command:
# $./resizeAssets.sh 640 960 ./graphics/ginormous ./graphics/wvga 

set -u #referencing undefined variable causes error
set -x #print out everything it does
set -e #anything with non-zero exit status aborts script

resizeGraphics()
{
 targetWidth=$1
 targetHeight=$2
 fullSizeDir="${3}"
 outDir="${4}"
 
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
			

			if ! grep "${atlas}" "${outDir}/compress.tmp" > /dev/null 2>&1; then
				echo "${atlas}:compression=${compression:-no}" >> "${outDir}/compress.tmp"
			fi
				
			#if a specific target size is specified, these variables will be set
			absoluteX=$(echo ${resize} | cut -s -dx -f1)
			absoluteY=$(echo ${resize} | cut -s -dx -f2)

			#alternates stored to be processed later - alternate sets must not span multiple resize.data files
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
				
				roadFilesExist=$(find ${resizeDir} -type f -name ${glob%.png}.road)
				
				if [ x${roadFilesExist:+set} = xset ]; then
					
					#generate new .road data with scaled road bounds
					
					find ${resizeDir} -type f -name ${glob} | while read file; do
						
						fullSizeX=$(convert "${file}" -format %w info:)
						fullSizeY=$(convert "${file}" -format %h info:)
						
						xScaleFactor=$(echo "scale=12; ${targetScreenWidth} / ${absoluteX}" | bc | xargs printf "%f")
						yScaleFactor=$(echo "scale=12; ${targetScreenHeight} / ${absoluteY}" | bc | xargs printf "%f")
						
						echo "${xScaleFactor} ${yScaleFactor}" >> "${outDir}/$(basename ${file%.png}).road"
						
						#scale each coordinate
						
						cat "${file%.png}.road" | while read roadLine; do
							
							#skip first line of file (scale factors from ginormous dir are irrelevent)
							isCoordinate=$(echo "${roadLine}" | cut -s -d' ' -f3)
							
							if [ x${isCoordinate:+set} = xset ]; then
							
								oldRoadBoundY=$(echo "${roadLine}" | cut -s -d' ' -f1) 
								oldRoadBoundX1=$(echo "${roadLine}" | cut -s -d' ' -f2)
								oldRoadBoundX2=$(echo "${roadLine}" | cut -s -d' ' -f3)

								newRoadBoundY=$(echo "scale=12; ${oldRoadBoundY} * (${absoluteY} / ${fullSizeY})" | bc | xargs printf "%1.0f")
								newRoadBoundX1=$(echo "scale=12; ${oldRoadBoundX1} * (${absoluteX} / ${fullSizeX})" | bc | xargs printf "%1.0f")
								newRoadBoundX2=$(echo "scale=12; ${oldRoadBoundX2} * (${absoluteX} / ${fullSizeX})" | bc | xargs printf "%1.0f")
								
								echo "${newRoadBoundY} ${newRoadBoundX1} ${newRoadBoundX2}" >> "${outDir}/$(basename ${file%.png}).road"
							fi
						done
						
						#output .road and .atl files with scaled coords
						echo "$(basename ${file}),+1,+1,-${xScaleFactor},-${yScaleFactor}" >> "${outDir}/${atlas}.atl"
						
					done
				fi
				

				if [ x${realrect:+set} = xset ]; then
				
					#write scaled bounds to realrect.bounds file for collision handling override
					#realrect variable will be a comma-delimited something like this: FatGuy01,0,282,304,31,1,1
					
					realrectFile=$(echo "${realrect}" | cut -s -d, -f1)
					
					realrectFileExists=$(find ${resizeDir} -type f -name "${realrectFile}.png")
					
					if [ x${realrectFileExists:+set} = xset ]; then
					
						originalWidth=$(convert "${resizeDir}/${realrectFile}.png" -format %w info:)
						rectScale=$(echo "scale=12; (${targetWidth} * ${resize}) / ${originalWidth}" | bc)
						
						realrectLine="image: ${realrectFile}"
						
						for i in 2 3 4 5
						do
							realrectBound=$(echo "${realrect}" | cut -s -d, -f${i})
							newBound=$(echo "scale=12; (${realrectBound} * ${rectScale})" | bc | xargs printf "%1.0f")
							realrectLine="${realrectLine} ${newBound}"
						done
						
						#these scale factors seem useless if we're already appropriately scaling the top,left,right & left bounds
						realrectScaleFactorX=$(echo "${realrect}" | cut -s -d, -f6)
						realrectScaleFactorY=$(echo "${realrect}" | cut -s -d, -f7)
						
						realrectLine="${realrectLine} ${realrectScaleFactorX} ${realrectScaleFactorY}"
						echo "${realrectLine}" >> "${outDir}/realrect.bound"
					fi
					
				fi
			fi
		fi
    done
done

#handle alternates stored in *.alternate.tmp files in the current directory being resized
#each alternate set will have a different .alternate.tmp file associated with it
find . -type f -name '*.alternates.tmp' | while read alternateFile; do

	currDir=$(dirname ${alternateFile})
	
	cat ${alternateFile} | while read alternate; do
	
		altglob=$( echo "${alternate}" | cut -s -d: -f1  | cut -s -d= -f2)
		targetAspect=$(echo "scale=12; ${targetScreenWidth} / ${targetScreenHeight}" | bc )

		#get aspect ratio of image and divide by targetAspectRatio and append to front of alternate and write to a tmp file
		imageWidth=$(convert "${currDir}/${altglob}" -format %w info:)
		imageHeight=$(convert "${currDir}/${altglob}" -format %h info:)
		imageAspect=$(echo "scale=12;  ${imageWidth} / ${imageHeight}" | bc )
		difference=$(echo "scale=12; ${imageAspect} - ${targetAspect}" | bc )
		absoluteDifference=${difference#-}
			
		#add a new alternate possibility to the file
		echo ${absoluteDifference}:${alternate} >> ${currDir}/alternates.ratios.tmp
		#sort lines in file so that closest ratio to target aspect ratio is at the top
		sort -n -t ':' -k 1 ${currDir}/alternates.ratios.tmp
		#pull out the closest option
		closest=$(head -n 1 ${currDir}/alternates.ratios.tmp)
		#save only the closest option
		echo ${closest} > "${currDir}/alternates.ratios.tmp"
	done
	
	#pull data out of the closest match to the target aspect ratio
	cat "${currDir}/alternates.ratios.tmp" | tr ':' '\n'  > "${currDir}/closest.alternate.tmp"
	closestGlob=$(grep 'glob=' ${currDir}/closest.alternate.tmp  | cut -s -d= -f2)
	closestAtl=$(grep 'atl=' ${currDir}/closest.alternate.tmp  | cut -s -d= -f2)
	closestResize=$(grep 'resize=' ${currDir}/closest.alternate.tmp  | cut -s -d= -f2)
	closestWidth=$(echo "${targetWidth} * ${closestResize}" | bc)
	
	rm ${currDir}/alternates.ratios.tmp
	rm ${currDir}/closest.alternate.tmp
	
	find "${currDir}" -type f -name "${closestGlob}" | while read image; do
		#strip off alternate's letter-underscore prefix so that wvga gets a predictable filename from any of the alternate options
		outputName="$(basename ${image})"
		outputName="${outputName#??}"
		`convert "${image}" -define png:color-type=6 -resize ${closestWidth} "${outDir}/${outputName}"`
		echo $(basename ${outputName}) >> "${outDir}/${closestAtl}.atl"
	done
	
	rm "${alternateFile}"
done

}

usage()
{
	echo "USAGE: <target-Screen-Width> <target-Screen-Height> <fullsize-src-dir> <resized-dest-dir>"
	exit 1;
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
	
	if [ -d "${destDir}" ]; then
		rm -rf "${destDir}"
	fi

	mkdir -p "${destDir}"
	
	resizeGraphics ${targetScreenWidth} ${targetScreenHeight} ${srcDir} ${destDir}
}

main ${@}
