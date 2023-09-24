# Common tools

## container
```shell
docker pull chelyshkin/ansible:latest
docker run --rm -ti chelyshkin/ansible:latest bash
```

## ansible-cli.sh
Bash script for install ansible on local machine and configure workspace.  

#### Default params:
- ```VENV_PATH="${HOME}/.ansible"```
- ```ANSIBLE_CFG_PATH="${HOME}/.ansible.cfg"```
- ```ANSIBLE_PLAYBOOKS_GIT_URL="https://github.com/mr-chelyshkin/environment.git"```
- ```ANSIBLE_PLAYBOOKS_GIT_BRANCH="master"```

#### Cli command:
- [install]          - Install ansible to local machine
- [remove]           - Remove ansible from local machine
- [wiki]             - Show ansible commands examples (for /mr-chelyshkin/environment.git)
- [update-playbooks] - Update local playbooks from git repository

#### Cli flags:
- [-h] - show help
- [-p] - Set path to python3 bin file (if not set: try to find python automatically)
- [-r] - change ANSIBLE_PLAYBOOKS_GIT_URL
- [-b] - change ANSIBLE_PLAYBOOKS_GIT_BRANCH


