# Base image
FROM alpine:latest
 
# installes required packages for our script
RUN	apk add --no-cache \
  bash \
  ca-certificates \
  curl \

RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install
 
# Copies your code file  repository to the filesystem
COPY entrypoint.sh /entrypoint.sh
 
# change permission to execute the script and
RUN chmod +x /entrypoint.sh
 
# file to execute when the docker container starts up
ENTRYPOINT ["/entrypoint.sh"]
