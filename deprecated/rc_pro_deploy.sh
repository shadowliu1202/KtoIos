#!/bin/bash

env='pro'
version=$1

ansible-playbook /data-disk/brand-deployment-document/playbooks/deploy-android-apk.yml --extra-vars "tag={version}" -i /data-disk/brand-deployment-document/playbooks/{env}.ini