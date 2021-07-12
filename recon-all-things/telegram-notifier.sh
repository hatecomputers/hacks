#!/bin/bash

curl -s https://api.telegram.org/bot$TELEGRAM_TOKEN/sendMessage --data-urlencode "parse_mode=html" --data-urlencode "chat_id=70244457" --data-urlencode "text=`cat $1`"
