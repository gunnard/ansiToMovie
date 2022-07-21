FROM ubuntu:22.04 

# Install system dependencies
RUN apt-get update && apt-get install -y git vim

RUN apt-get install -y ffmpeg
RUN apt-get install -y imagemagick
RUN apt-get install -y ansilove
RUN apt-get install -y zip unzip
RUN apt-get install -y file
RUN apt-get install -y bc