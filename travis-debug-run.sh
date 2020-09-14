#! /usr/bin/env bash

if [ -z $1 ]; then
  echo "Please input job ID"
  exit
fi

JOB_ID=$1
API_TOKEN=cVnK5OYbXaS5UsDp6E6P2g
curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "Travis-API-Version: 3" \
  -H "Authorization: token $API_TOKEN" \
  -d '{ "quiet": true }' \
  https://api.travis-ci.com/job/$JOB_ID/debug 
