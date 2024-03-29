#!/bin/bash
shopt -s nullglob dotglob
# Ansi color code variables
red="\e[0;91m"
blue="\e[0;94m"
expand_bg="\e[K"
blue_bg="\e[0;104m${expand_bg}"
red_bg="\e[0;101m${expand_bg}"
green_bg="\e[0;102m${expand_bg}"
green="\e[0;92m"
white="\e[0;97m"
bold="\e[1m"
uline="\e[4m"
reset="\e[0m"

outname=`pwd`
IFS='/' read -ra my_array <<< "$outname"

echo "[==========================================]"
echo "| creating backup ../clean_${my_array[-1]} |"
echo "[==========================================]"
cp -R ${outname} ../clean_${my_array[-1]}

if [ ! -d "mp4" ]; then
	mkdir mp4
fi
if [ ! -d "png" ]; then
	mkdir png
fi
if [ ! -d "old" ]; then
	mkdir old
fi
if [ ! -d "tiktok" ]; then
	mkdir tiktok 
fi

if [ -z "$1" ]

then
	FinalOutName=${my_array[-1]}.mp4
else
	FinalOutName=$1
fi
echo "[==============================]"
echo "| Begin creating $FinalOutName |"
echo "[==============================]"

if [ -f "ACIDVIEW.EXE" ]; then
	echo "Removing AcIDVIEW files"
	rm ACIDVIEW*
fi

if [ -f "ICEVIEW.EXE" ]; then
	echo "Removing iCEVIEW files"
	rm ICEVIEW*
fi

if [ -f "WE-WILL.SUE" ]; then
	echo "Removing WE-WILL.SUE"
	rm WE-WILL.SUE
fi

fileTypes=("*.GIF" "*.gif")
for fileType in "${fileTypes[@]}"
do
	files=($fileType)
	if [ -n "$files" ]; then
		for ((i=0; i<${#files[@]}; i++)); do
			cleanFile=${files[$i]//!/}
			cleanFile=${cleanFile// /}
			cleanFile=${cleanFile//^/}
			cleanFile=${cleanFile//+/}
			cleanFile=${cleanFile//&/}
			cleanFile=${cleanFile//%/}
			if [ "$cleanFile" != "${files[$i]}" ]; then
				echo "Cleaning....."
				echo $cleanFile "--" ${files[$i]}
				mv "${files[$i]}" ${cleanFile}
			fi
		done
	fi
done

numFiles=()
fileTypes=("*.GRT" "*.BIN" "*.LGO" "*.CIA" "*.WKD" "*.wkd" "*.VIV" "*.viv" "*.FL" "*.IMP" "*.txt" "*.ans" "*.asc" "*.LGC" "*.ASC" "*.NFO" "*.ANS" "*.ans" "*.DRK" "*.ICE" "*.LIT" "*.MEM" "*.DIZ" "*.STS" "*.MEM" "*.GOT" "*.rmx")
for fileType in "${fileTypes[@]}"
do
	files=($fileType)
	if [ -n "$files" ]; then
		for ((i=0; i<${#files[@]}; i++)); do
			cleanFile=${files[$i]//!/}
			cleanFile=${cleanFile// /}
			cleanFile=${cleanFile//^/}
			cleanFile=${cleanFile//+/}
			cleanFile=${cleanFile//&/}
			cleanFile=${cleanFile//%/}
			if [ "$cleanFile" != "${files[$i]}" ]; then
				echo "Cleaning....."
				echo $cleanFile "--" ${files[$i]}
				mv "${files[$i]}" ${cleanFile}
			fi
			theFiles+=("${files[$i]}")
			echo "adding: ${files[$i]}\n"
		done
	fi
done

fileType=()
files=()
unset theFiles
for fileType in "${fileTypes[@]}"
do
	files=($fileType)
	if [ -n "$files" ]; then
		for ((i=0; i<${#files[@]}; i++)); do
			if [[ ${theFiles[*]} =~ ${files[$i]} ]]
			then
				echo "Skipping Dupe ${files[$i]}\n"
			else
				theFiles+=("${files[$i]}")
				echo "adding new: ${files[$i]}\n"
			fi
		done
	fi
done

jpgTypes=("*.jpg" "*.JPG")
for jpg in "${jpgTypes[@]}"
do
	files=($jpg)
	if [ -n "$files" ]; then
		for ((i=0; i<${#files[@]}; i++)); do
			convert ${files[$i]} ${files[$i]}.png
			rm ${files[$i]}
			echo -e ${green}"converting "${files[$i]}" to  png"${reset}
		done
	fi
done

gifTypes=("*.GIF" "*.gif")
for gif in "${gifTypes[@]}"
do
	files=($gif)
	if [ -n "$files" ]; then
		for ((i=0; i<${#files[@]}; i++)); do
			gif2png -O -d -p ${files[$i]}
			echo -e ${green}"converting "${files[$i]}" to  png"${reset}
			#ffmpeg -stream_loop 20 -i ${files[$i]} ${files[$i]}-loop.gif -y
			#ffmpeg -i ${files[$i]}-loop.gif -pix_fmt yuv420p -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" ${files[$i]}.mp4 -y
			rm ${files[$i]}
		done
	fi
done

numFiles=${#theFiles[@]}
processedFiles=0

echo "Total files to encode: ${numFiles}"
for name in "${theFiles[@]}"
do
	((processedFiles++))
	ansilove -q -d -S ${name}
	filesize=$(file $name.png | awk 'NR==1{print $7}')
	filesize=${filesize::-1}
	if [ $filesize -gt 480 ] 
	then
		echo -e "("${green}${processedFiles}${reset}"/"${green}${numFiles}${reset}") size: "${filesize}" ---> Video " $name
		ffmpeg -hide_banner -loglevel panic -f lavfi -i color=s=1920x1080 -loop 1 -t 0.08 -i "$name".png -filter_complex "[1:v]scale=1920:-2,setpts=if(eq(N\,0)\,0\,1+1/0.02/TB),fps=25[fg]; [0:v][fg]overlay=y=-'t*h*0.02':eof_action=endall[v]" -map "[v]" $name.mp4 -nostdin
		rm $name.png		
		mv $name.mp4 mp4/
	else 
		echo -e "("${green}${processedFiles}${reset}"/"${green}${numFiles}${reset}") ---> png " $name
	fi
		mv $name old/
done 

mp4s=(mp4/*)
pngs=(*.png)

if [ ${#mp4s[@]} -gt ${#pngs[@]} ]
then
	maxPngs=${#pngs[@]}
else
	maxPngs=${#mp4s[@]}
fi
echo -e "("${green}${#pngs[@]}${reset}"/"${green}${#mp4s[@]}${reset}")" 
echo "Adding pngs to mp4s"
processedPngs=0
for ((i=0; i<${maxPngs}; i++)); do
	((processedPngs++))
	echo -e "("${green}${processedPngs}${reset}"/"${green}${maxPngs}${reset}") Adding " ${pngs[$i]} " to " ${mp4s[$i]}
	ffmpeg -hide_banner -loglevel panic -loop 1 -i "${pngs[$i]}" -pix_fmt yuv420p -t 8 -vf scale=800:600 ${pngs[$i]}.mp4
	echo file ${pngs[$i]}.mp4 > list.txt
	echo file ${mp4s[$i]} >> list.txt
	ffmpeg -hide_banner -loglevel panic -f concat -i list.txt -c copy new-${pngs[$i]}.mp4
	echo -e ${green}"Copying new-"${pngs[$i]}".mp4 to  mp4/"${reset}
	mv ${pngs[$i]} png/
	mv ${pngs[$i]}.mp4 old/
	mv ${mp4s[$i]} old/
	rm list.txt
done

#move concatted png+mp4 to /mp4
newmp4s=(*.mp4)

newmp4files=${#newmp4s[@]}
for ((i=0; i<${newmp4files}; i++)); do
	echo -e ${green}"Copying "${newmp4s[$i]}" to  mp4/"${reset}
	mv ${newmp4s[$i]} mp4/
done
#-------------

mp4s=(mp4/*)
pngs=(*.png)

if [ ${#pngs[@]} -gt 0 ]
then
	touch list.txt
	for ((i=0; i<${#pngs[@]}; i++)); do
		echo -e "("${green}${i}${reset}"/"${green}${#pngs[@]}${reset}") Adding " ${pngs[$i]}
		ffmpeg -hide_banner -loglevel panic -loop 1 -i "${pngs[$i]}" -pix_fmt yuv420p -t 8 -vf scale=800:600 ${pngs[$i]}.mp4
		echo file ${pngs[$i]}".mp4" >> list.txt
		mv ${pngs[$i]} png/
	done
	echo "Making final png mp4"
	ffmpeg -hide_banner -loglevel panic -f concat -i list.txt -c copy new-allother.mp4
	mv new-allother.mp4 mp4/
	rm list.txt
fi

touch list.txt
finalmp4s=(mp4/*)
finalmp4s=( $(shuf -e "${finalmp4s[@]}") )
if [ -f "img/intro.mp4" ]; then
	echo "file img/intro.mp4" >> list.txt
fi


for ((i=0; i<${#finalmp4s[@]}; i++)); do
	echo "("${i}"/"${#finalmp4s[@]}") Adding " ${finalmp4s[$i]}
	echo file ${finalmp4s[$i]} >> list.txt
done

if [ -f "img/outtro.mp4" ]; then
	echo "outtro"
	echo "file img/outtro.mp4" >> list.txt
fi

ffmpeg -hide_banner -loglevel panic -f concat -i list.txt -c copy realFinal.mp4

duration=$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of csv=p=0 realFinal.mp4)
fade=5


allMp3s=(/tmp/mp3s/*.mp3)
shuffled=( $(shuf -e "${allMp3s[@]}") )
touch /tmp/shuffMp3s.txt
newMp3s=("*.MP3")
if [ -n "$newMp3s" ]; then
	for newMp3 in ${newMp3s[@]}; do
		cp $newMp3 /tmp/mp3s
		echo file /tmp/mp3s/$newMp3 >> /tmp/shuffMp3s.txt
	done
fi

for mp31 in ${shuffled[@]}; do
    echo file $mp31 >> /tmp/shuffMp3s.txt
done
echo "Joining random mp3s"
ffmpeg -hide_banner -loglevel panic -f concat -safe 0 -i /tmp/shuffMp3s.txt -c copy /tmp/shuffmp3.mp3
mv /tmp/shuffMp3s.txt .
echo 'Combining mp3 with video'

ffmpeg -hide_banner -loglevel panic -i realFinal.mp4 -i /tmp/shuffmp3.mp3 -filter_complex "[1:a]afade=t=out:st=$(bc <<< "$duration-$fade"):d=$fade[a]" -map 0:v:0 -map "[a]" -c:v copy -c:a aac -shortest ${FinalOutName}
rm mp4/new-allother.mp4
rm /tmp/shuffmp3.mp3
#rm realFinal.mp4

echo "[===============]"
echo "END $FinalOutName"
echo "[===============]"

touch list.txt
echo 'Making Tiktoks'
tiktoks=(mp4/*)
for ((i=0; i<${#tiktoks[@]}; i++)); do
	echo "("${i}"/"${#tiktoks[@]}") tiktoking  "${tiktoks[$i]}
	if [ -f "img/intro.mp4" ]; then
		echo "file img/intro.mp4" >> list.txt
	fi
	echo file ${tiktoks[$i]} >> list.txt
    ffmpeg -hide_banner -loglevel panic -f concat -i list.txt -c copy ${tiktoks[$i]}-no-sound.mp4
    rm list.txt
    duration=$(ffprobe -v error -select_streams v:0 -show_entries stream=duration -of csv=p=0 ${tiktoks[$i]}-no-sound.mp4)
    fade=5
    allMp3s=(/tmp/mp3s/*.mp3)
    shuffled=( $(shuf -e "${allMp3s[@]}") )
    touch /tmp/shuffMp3s.txt
    for mp31 in ${shuffled[@]}; do
        echo file $mp31 >> /tmp/shuffMp3s.txt
    done
    echo "Joining random mp3s"
    ffmpeg -hide_banner -loglevel panic -f concat -safe 0 -i /tmp/shuffMp3s.txt -c copy /tmp/shuffmp3.mp3
    echo 'Combining mp3 with video'
    rm /tmp/shuffMp3s.txt

    IFS='/' read -ra my_array <<< "${tiktoks[$i]}"
    ffmpeg -hide_banner -loglevel panic -i ${tiktoks[$i]}-no-sound.mp4 -i /tmp/shuffmp3.mp3 -filter_complex "[1:a]afade=t=out:st=$(bc <<< "$duration-$fade"):d=$fade[a]" -map 0:v:0 -map "[a]" -c:v copy -c:a aac -shortest tiktok/${my_array[-1]}.mp4
    rm ${tiktoks[$i]}-no-sound.mp4
    rm /tmp/shuffmp3.mp3
done

echo "[===============]"
echo "END making tiktoks"
echo "[===============]"
