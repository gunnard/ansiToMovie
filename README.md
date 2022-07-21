# ansiToMovie

## Requirements:
Ansilove https://www.ansilove.org/

FFmpeg
https://ffmpeg.org/

``docker-compose up -d``
to connect:

``docker exec -ti ansiToMovie bash``

``/ansi`` and ``/mp3s`` are mapped to your host computer. put the files there

This version checks for ``intro.mp4`` in the pack directory and puts it first if available

Edit line #183 to point to where your music is.

``183 allMp3s=(/home/XXXXXXXXXX/Music/*.mp3)``
