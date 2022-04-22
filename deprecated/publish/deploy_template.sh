#!/bin/bash

FTP='ftp://10.10.16.65/release/mobile/'
ENV='pro'
version=$1
MESSAGE=$2
if [[ "$MESSAGE" == "" ]]
then
  MESSAGE="[Android]_Kto-Asia_apk_has_bean_deployed"
COLOR=00ff00
fi
TARGET='ext-nginx-mobile'
DOWNLOADPAGE='https://appkto.com/'
WEBHOOK='https://higgstar.webhook.office.com/webhookb2/9b048c31-83f5-44dc-ae45-bb317534b066@8e771fc0-280e-4271-a200-ad98dd5f6605/IncomingWebhook/4398a37e0c3249b0bbcce35f75e23d78/dbab47a2-891a-470f-a94e-4dbb41d9acbc'
CURRDATE=$(date '+%Y%m%d')
TITLE="Mobile_Team_Production_Deployment_-_"$CURRDATE
extra_var="host=${TARGET} env=${ENV} version=$version ftp=$FTP webhook=$WEBHOOK title=$TITLE webpage=$DOWNLOADPAGE message=$MESSAGE"
ansible-playbook test_nginx_deploy.yml --extra-vars "$extra_var" -i ngx_pro.ini
