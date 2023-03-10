#!/bin/bash

# DayZ ChernarusPlus Map Downloader
# Created by Samg381 | samg381.com
# Usage: ./getmap [Res] [Type]
#		 [Res]  Map resolution: 1-8
#		[Type]  Map image type: sat, top

RES=$1
TYP=$2

printf "Downloading $TYP map at ${RES}x resolution.\n"

if [ $RES == 1 ]; then
	SIZE=1
elif [ $RES == 2 ]; then
	SIZE=3
elif [ $RES == 3 ]; then
	SIZE=7
elif [ $RES == 4 ]; then
	SIZE=15
elif [ $RES == 5 ]; then
	SIZE=31
elif [ $RES == 6 ]; then
	SIZE=63
elif [ $RES == 7 ]; then
	SIZE=127
elif [ $RES == 8 ]; then
	SIZE=255
	printf "Warning! You have selected 8x resolution- This will create a FOUR GIGAPIXEL (65000x65000px) image. This will take a while!\n"
else
	printf "Please specify a valid resolution (1-8) ( ex: ./getmap 4 sat )\n"
	exit;
fi




printf "Setting up...\n"

mkdir -p maps
rm -r -f tmp > /dev/null 2>&1
mkdir -p tmp
ulimit -n 2048

touch TilesToDownload.txt
truncate -s 0 TilesToDownload.txt

TOT=$((SIZE+1))




printf "Generating download list...\n"

for (( y=0; y<=$SIZE; y++ ))
do
	for (( x=0; x<=$SIZE; x++ ))
	do
	
		xFileName=$(printf "%03d" $x)
		yFileName=$(printf "%03d" $y)
	
		
		# echo https://maps.izurvive.com/maps/ChernarusPlus-Top/1.19.0/tiles/"$RES"/"$x"/"$y".jpg | xargs wget -O "${yFileName}_${xFileName}.jpg" > /dev/null 2>&1
		
		# aria2c -x 16 -o "${yFileName}_${xFileName}.jpg" https://maps.izurvive.com/maps/ChernarusPlus-Top/1.19.0/tiles/"$RES"/"$x"/"$y".jpg > /dev/null 2>&1
		
		
		if [ $2 == "top" ]; then
			echo https://maps.izurvive.com/maps/ChernarusPlus-Top/1.19.0/tiles/"$RES"/"$x"/"$y".jpg >> TilesToDownload.txt
			echo "	out=${yFileName}_${xFileName}.jpg" >> TilesToDownload.txt
		elif [ $2 == "sat" ]; then
			echo https://maps.izurvive.com/maps/ChernarusPlus-Sat/1.19.0/tiles/"$RES"/"$x"/"$y".jpg >> TilesToDownload.txt
			echo "	out=${yFileName}_${xFileName}.jpg" >> TilesToDownload.txt
		else
			printf "Please specify satellite / topographic (sat/top) ( ex: ./getmap 4 sat )\n"
			exit;
		fi
	
		
		if [ $RES -ge 5 ]
		then
			if ! (( $x % 10 )) ; then
				if ! (( $y % 10 )) ; then
					printf "[${yFileName}_${xFileName}]"
				fi
			fi
		else
			printf "[${yFileName}_${xFileName}]"
		fi
	
		
	done
	
	if [ $RES -ge 5 ]
	then
		if ! (( $y % 10 )) ; then
			printf "\n"
		fi
	else
		printf "\n"
	fi
	
done



printf "Done.\nInitiating download (this may take a while)\n"

aria2c --dir=./tmp --input-file=TilesToDownload.txt --max-tries=0 --retry-wait=3 --timeout=5 --max-concurrent-downloads=400 --connect-timeout=60 --max-connection-per-server=16 --split=16 --min-split-size=1M --download-result=full --file-allocation=none

# max-concurrent-downloads (getmap 7 sat) speed tests:
# 300: 1:13
# 500: 1:12
# 600: 1:11
# 800: Errors

printf "Downloads complete!\n"

rm TilesToDownload.txt

cd tmp



# If resolution is 8, saving each tile at 256x256 resolution will cause an error when we concatenate, as the max JPG size is 65500. 
# So, we check if the resolution is 8, and if so resize each tile to 254x254 BEFORE concatenating.
if [ $RES -ge 8 ]
then
	printf "Resizing tiles prior to concatenation to avoid .JPG 65500 max overshoot.\n"
	mogrify -resize 254x254 -format jpg *.jpg
	printf "Resizing complete.\n"
fi

printf "Generating map from tiles. This may take a while.\n"

montage -monitor -mode concatenate *_*.jpg -tile "${TOT}x${TOT}" "${TOT}x${TOT}_${2}.jpg"

printf "Map generation complete! Opening image (saved in maps folder)\n"




mv "${TOT}x${TOT}_${2}.jpg" ../maps

cd ../maps

explorer.exe "${TOT}x${TOT}_${2}.jpg"

cd ..

rm -r -f tmp
