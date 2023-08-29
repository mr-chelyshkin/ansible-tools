#!/bin/bash

# Update playbook sources
cd /root/.ansible/environment && ansible-cli update-playbooks

# Activate the virtual environment
source /root/.ansible/bin/activate

# Execute command
exec "$@"
