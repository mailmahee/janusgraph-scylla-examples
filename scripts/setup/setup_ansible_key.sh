#!/usr/bin/env bash
#
# Setup Ansible key
#
# 2019 - Ryan Stauffer, Enharmonic, Inc.

SSH_USERNAME=ansible
KEY_PATH=$HOME/.ssh/$SSH_USERNAME
ssh-keygen -t rsa -f $KEY_PATH -C $SSH_USERNAME
chmod 400 $KEY_PATH
