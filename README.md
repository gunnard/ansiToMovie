# ansiToMovie

## Requirements:

Docker

``docker-compose up -d``
to connect:

``docker exec -ti ansiToMovie bash``

``/ansi`` and ``/mp3s`` are mapped to your host computer. put the files there

you should create an ``img/`` directory within each unzipped pack for your assets like intro.mp4 and thumbnails.

This version checks for ``img/intro.mp4`` in the pack directory and puts it first if available

copy ``ansiToMovie.sh`` to ``/usr/bin`` if you want to run this globally
