#!/bin/sh

# Help.
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  echo 'Usage: teams-chat-post.sh "<webhook_url>" "<title>" "<version>" "<env>" "<webpage>"'
  exit 0
fi

# Webhook or Token.
WEBHOOK_URL=$1
if [[ "${WEBHOOK_URL}" == "" ]]
then
  echo "No webhook_url specified."
  exit 1
fi
shift

# Title .
TITLE=$1
if [[ "${TITLE}" == "" ]]
then
  echo "No title specified."
  exit 1
fi
shift

VERSION=$1
if [[ "${VERSION}" == "" ]]
then
  echo "No version specified."
  exit 1
fi
shift

ENV=$1
if [[ "${ENV}" == "" ]]
then
  echo "No enviroment specified."
  exit 1
fi
shift

WEB=$1
if [[ "${WEB}" == "" ]]
then
  echo "No web link specified."
  exit 1
fi
shift

TEXT=$1
if [[ "{$TEXT}" == "" ]]
then
  echo "No MESSAGE specified."
  exit 1
fi

# Color.
COLOR=00ff00

TEXT_BLANK=${TEXT//_/' '}
TITLE_BLANK=${TITLE//_/' '}

# Convert formating.
MESSAGE=$( echo ${TEXT_BLANK} | sed 's/"/\"/g' | sed "s/'/\'/g" )
FACTS="[{\"facts\": [
{\"name\": \"version:\",\"value\": \"${VERSION}\"},
{\"name\": \"download page:\",\"value\": \"<a href='${WEB}'>${WEB}</a>\"},
{\"name\": \"related issue:\",\"value\": \"<a href='https://jira.higgstar.com/issues/?jql=project%20%3D%20Mobile%20%20AND%20fixVersion%20%3D%20android-${VERSION}%20'>Jira Issues</a>\"}
]}]"
JSON="{\"title\": \"${TITLE_BLANK}\", \"themeColor\": \"${COLOR}\",\"text\":\"$MESSAGE\",\"sections\":$FACTS}"
# Post to Microsoft Teams.
curl -H "Content-Type: application/json" -d "${JSON}" "${WEBHOOK_URL}"
