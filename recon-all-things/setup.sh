#!/bin/bash

# colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[1;36m'
NC='\033[0m'

echo -e "${PURPLE}"
cat <<"EOF"
crafted out of misery by
 _           _                                       _
| |__   __ _| |_ ___  ___ ___  _ __ ___  _ __  _   _| |_ ___ _ __ ___
| '_ \ / _` | __/ _ \/ __/ _ \| '_ ` _ \| '_ \| | | | __/ _ \ '__/ __|
| | | | (_| | ||  __/ (_| (_) | | | | | | |_) | |_| | ||  __/ |  \__ \
|_| |_|\__,_|\__\___|\___\___/|_| |_| |_| .__/ \__,_|\__\___|_|  |___/
                                      |_|
                                                        version 0.0.1
EOF
echo -e "${NC}"

# Download all the go dependencies
GO111MODULE=on go get -u -v github.com/tomnomnom/assetfinder
GO111MODULE=on go get -u -v github.com/projectdiscovery/shuffledns/cmd/shuffledns
GO111MODULE=on go get -u -v github.com/projectdiscovery/httpx/cmd/httpx
GO111MODULE=on go get -u -v github.com/gwen001/github-subdomains

cp ~/go/bin/* /usr/local/bin 

# Download Sublist3r
cd /opt && git clone https://github.com/aboul3la/Sublist3r.git sublist3r && cd sublist3r
pip install -r /opt/sublist3r/requirements.txt

# Download findomain
cd /opt && wget https://github.com/findomain/findomain/releases/latest/download/findomain-linux
chmod +x findomain-linux
cp findomain-linux /usr/local/bin/findomain

echo -e "Done. You will need to export those variables to get the most of it:"
echo -e "${YELLOW}"
cat <<"EOF"

export GITHUB_API=<your_github_key>
export SECURITY_TRAILS_API=<your_security_trails_key>
export TELEGRAM_TOKEN=<your_telegram_bot_token>
export NOTIFY_ON_TELEGRAM=true/false
EOF
echo -e "${NC}"
