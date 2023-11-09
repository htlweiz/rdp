FROM lscr.io/linuxserver/code-server:latest
RUN apt-get clean && \
apt-get update && \
apt-get upgrade -y && \
apt-get install -y \
  nginx \
  python3 \
  python3-pip \
  python3-venv \
  ca-certificates \
  gnupg \
  inotify-tools \
  psmisc \
  curl && \
  mkdir -p /etc/apt/keyrings && \
  echo KEYRING DONE ** && \
  curl -fsSl https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg && \
  echo CURL DONE ** && \
  export NODE_MAJOR=16 && \
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_${NODE_MAJOR}.x nodistro main" > /etc/apt/sources.list.d/nodesource.list && \
  apt-get update && \
  apt-get install -y nodejs && \
echo '**** All Done ****'
