#!/bin/bash

DOMAIN=$1
TERM=$(echo $DOMAIN | cut -d '.' -f1)
DIR=$2

# colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
PURPLE='\033[1;36m'
NC='\033[0m'

if [ -z "$DOMAIN" ]; then
       echo "DOMAIN has to have value"
       echo "Usage: ./recon-all-things.sh <domain> <output_dir>"
       echo "Example: ./recon-all-things.sh tesla.com"
       exit 0
fi

if [ -z $DIR ]; then
	DIR=$(pwd)
fi

if [ -n $DIR ]; then
	echo -e "${YELLOW}[-]${NC} $DIR was found."
	DATE=$(date +"%d%m%y")
	DIR=$DIR/recon$DATE
	echo -e "${YELLOW}[-]${NC} Creating a new scan at $DIR..."
fi

mkdir -p $DIR
rm $DIR/list* $DIR/hosts.txt $DIR/domains.txt $DIR/alive.txt 2>/dev/null

print_banner() {
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
export GITHUB_API=<your_github_key>
export SECURITY_TRAILS_API=<your_security_trails_key>
export TELEGRAM_TOKEN=<your_telegram_bot_token>
export NOTIFY_ON_TELEGRAM=true/false

Usage: recon-all-things <domain> <output_directory>
EOF
echo -e "${NC}"
}

run_security_trails () {
	if [ -z $SECURITY_TRAILS_API ]; then
		echo -e "(Security Trails) key ${RED}was not${NC} found. Skipping..."
	else
		curl -s "https://api.securitytrails.com/v1/domain/$DOMAIN/subdomains?children_only=true" -H "apikey: $SECURITY_TRAILS_API" | jq -r .subdomains[] 2>/dev/null | xargs -I@ sh -c "echo @.$DOMAIN >> $DIR/list1"
		echo -e "(Security Trails) ${YELLOW}$(cat $DIR/list1 | wc -l) domains${NC}"
	
	fi
}

run_assetfinder () {
	assetfinder -subs-only $DOMAIN >> $DIR/list2
	echo -e "(Assetfinder) ${YELLOW}$(cat $DIR/list2 | wc -l) domains${NC}"
}

run_sonar () {
	curl -s https://sonar.omnisint.io/subdomains/$DOMAIN | jq -r .[] >> $DIR/list3
	echo -e "(Sonar) ${YELLOW}$(cat $DIR/list3 | wc -l) domains${NC}"
}

run_findomain () {
	findomain -t $DOMAIN -q >> $DIR/list4 
	echo -e "(Findomain) ${YELLOW}$(cat $DIR/list4 | wc -l) domains${NC}"
}

run_sublist3r () {
	python3 /opt/sublist3r/sublist3r.py -d $DOMAIN -n >> $DIR/temp.txt 2>/dev/null; cat $DIR/temp.txt | grep "$DOMAIN" >> $DIR/list5; rm $DIR/temp.txt
	echo -e "(Sublist3r) ${YELLOW}$(cat $DIR/list5 | wc -l) domains${NC}"
}

run_crtsh () {
	curl -s https://crt.sh/?q=%25.$DOMAIN\&output=json | jq -r .[].name_value | grep -v "*" >> $DIR/list6
	echo -e "(crt.sh) ${YELLOW}$(cat $DIR/list6 | wc -l) domains${NC}"
}

run_github_subdomains () {
	if [ -z $GITHUB_API ]; then
		echo -e "(Github subdomains) key ${RED}was not${NC} found. Skipping..."
	else
		python3 /opt/github-search/github-subdomains.py -t $GITHUB_API -d $DOMAIN >> $DIR/list7
		echo -e "(Github subdomains) ${YELLOW}$(cat $DIR/list7 | wc -l) domains${NC}"
	fi
}

run_shuffledns () {
	shuffledns -silent -d $DOMAIN -$DIR/list8 /opt/sec/lists/Discovery/DNS/subdomains-top1million-20000.txt -r resolvers.txt
	echo "Found $(cat $DIR/list7 | wc -l) domains for Shuffle dns"
}


run_recon_dev () {
	if [ -z $RECON_DEV_API ]; then
		echo -e "(Recon.dev) key ${RED}was not${NC} found. Skipping..."
	else
		curl -X GET -H "Accept: application/json" "https://recon.dev/api/search?key=$RECON_DEV_KEY&domain=$DOMAIN" 
		echo -e "(Recon.dev) ${YELLOW}$(cat $DIR/list8 | wc -l) domains${NC}"
	fi
}

run_subfinder () {
	/usr/local/bin/subfinder -d $DOMAIN -silent >> $DIR/list9
	echo -e "(Subfinder) ${YELLOW}$(cat $DIR/list9 | wc -l) domains${NC}"
}

get_from_programs_folder () {
	PROGRAMS_FOLDER=/root/bugbounty/programs
	ZIP_FILE=$(ls $PROGRAMS_FOLDER | grep $TERM)
	if [ $? -eq "0" ]; then
		echo -e "File ${GREEN}found${NC} at $PROGRAMS_FOLDER/$ZIP_FILE..." 
		PROGRAM_FILES=$(unzip $PROGRAMS_FOLDER/$ZIP_FILE | grep "inflating" | awk -F " " '{print $NF}')
		cat $PROGRAM_FILES >> $DIR/list9
		rm $PROGRAM_FILES
		echo -e "(Programs folder) $(cat $DIR/list9 | wc -l) domains"
	else 
		echo "(Programs folder) error"
	fi
}

get_all_domains() {
	echo ""
	echo -e "${YELLOW}[+]${NC} Generating domains list..." 
	cat $DIR/list* | grep -Ev "\[|$^" | sort -u >> $DIR/hosts.txt
	rm $DIR/list*
	echo -e "${GREEN}Done.${NC}"
}

get_all_alive() {
	echo -e "${YELLOW}[+]${NC} Checking for domains with a webserver. This might take a awhile... "
	cat $DIR/hosts.txt | httpx -silent -threads 100 -no-color -retries 0 -timeout 3 >> $DIR/alive.txt
	echo -e "${GREEN}Done.${NC}"
}

show_report() {
	echo -e "\n${YELLOW} Final report:${NC}"
	echo -e "`pwd`/hosts.txt ${GREEN}$(cat $DIR/hosts.txt | wc -l)${NC}"
	echo -e "`pwd`/domains.txt ${GREEN}$(cat $DIR/domains.txt | wc -l)${NC}"
	echo -e "`pwd`/alive.txt ${GREEN}$(cat $DIR/alive.txt | wc -l)${NC}"
	echo -e "`pwd`/urls.txt ${GREEN}$(cat $DIR/urls.txt | wc -l)${NC}"
	echo -e "`pwd`/params.txt ${GREEN}$(cat $DIR/urls.txt | wc -l)${NC}"
}

notify_on_telegram() {
	if [[ -n $NOTIFY_ON_TELEGRAM ]]; then
		echo -e "${YELLOW}[+]${NC} Sending report on telegram..."
		echo -e "Hello master. Here's your latest scan results for <strong>$DOMAIN</strong>: \
			\n<strong>recon-all-things</strong> wrapped up at `date` \
			\n<strong>Domains</strong>: `cat $DIR/domains.txt | wc -l` \
			\n<strong>Hosts</strong>: `cat $DIR/hosts.txt | wc -l` \
			\n<strong>Alive</strong>: `cat $DIR/alive.txt | wc -l` \
			\n<strong>Urls</strong>: `cat $DIR/urls.txt | wc -l` \
			\n<strong>Params</strong>: `cat $DIR/params.txt | wc -l`
			\n\nHappy hacking." >> $DIR/telegram-temp.txt
		
		telegram-notifier $DIR/telegram-temp.txt &>/dev/null
		rm $DIR/telegram-temp.txt

		echo -e "${GREEN}Done.${NC}"
	fi
}

run_aquatone() {
	cat $DIR/alive.txt | /usr/local/bin/aquatone -chrome-path /snap/bin/chromium -out $DIR/screenshots
}

get_all_cached_urls (){
	echo -e "${YELLOW}[+]${NC} Getting all the cached urls..."
	cat $DIR/alive.txt | gau >> $DIR/urls_temp.txt; cat $DIR/alive.txt | waybackurls >> $DIR/urls_temp.txt
	cat $DIR/urls_temp.txt | sort -u | grep $TERM | grep -Ev "jpe?|png|woff|gif|svg|css" >> $DIR/urls.txt
	rm $DIR/urls_temp.txt
	echo -e "${GREEN}Done.${NC}"
}

get_all_url_params (){
	echo -e "${YELLOW}[+]${NC} Extracting all url params.."
	cat $DIR/urls.txt | grep -Eo "\w+=" | grep -v "utm" | sort -u >> $DIR/params.txt 
	echo -e "${GREEN}Done.${NC}"
}

print_banner
run_security_trails
run_assetfinder
run_sonar
run_findomain
run_sublist3r
run_crtsh
run_github_subdomains
run_subfinder
get_from_programs_folder
get_all_domains

echo -e "${YELLOW}[+]${NC} Spinning up the wheels to get more domains..."
cat $DIR/hosts.txt | cut -f2 | xargs -I@ -P50 sh -c "assetfinder @ -subs-only" >> $DIR/temp1 2>/dev/null 
cat $DIR/temp1 | xargs -I@ -P50 sh -c "assetfinder @ -subs-only" >> $DIR/temp2 2>/dev/null
cat $DIR/temp2 | xargs -I@ -P50 sh -c "assetfinder @ -subs-only" >> $DIR/temp3 2>/dev/null
cat $DIR/temp3 | xargs -I@ -P50 sh -c "assetfinder @ -subs-only" >> $DIR/temp4 2>/dev/null

cat $DIR/temp* | grep ${TERM} | grep -Ev "^$|\[" | anew $DIR/hosts.txt
rm $DIR/temp*
cat $DIR/hosts.txt | dnsx -silent -resp | awk -F " " '{print $2 "\t" $1}' | tr -d [] | sort -u >> $DIR/domains.txt
echo -e "${GREEN}Done.${NC}"

get_all_alive
get_all_cached_urls
get_all_url_params
run_aquatone
notify_on_telegram
show_report
echo -e "\nHappy hacking."
