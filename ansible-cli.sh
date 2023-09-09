#!/usr/bin/env bash

# script for install / remove ansible on local.
# script use system python3 or you can set path to python binary manually.
#
# SCRIPT HAS STATIC VENV AND ANSIBLE PATH: $HOME/.ansible
# SCRIPT CREATE ANSIBLE CONFIG FILE IN: $HOME/.ansible.cfg
#

ACTIONS="install remove wiki update-playbooks"
VENV_PATH="${HOME}/.ansible"

ANSIBLE_CFG_PATH="${HOME}/.ansible.cfg"

# this envs set as defaults, but it can be rewrite by [-r] commands flag.
ANSIBLE_PLAYBOOKS_GIT_URL="https://github.com/mr-chelyshkin/environment.git"
# this envs set as defaults, but it can be rewrite by [-b] commands flag.
ANSIBLE_PLAYBOOKS_GIT_BRANCH="main"

PYTHON_PATH=""
ACTION=""

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'


############################################################
# Set Git repository envs                                  #
############################################################
SetGitRepositoryEnvs() {
  no_scheme="${ANSIBLE_PLAYBOOKS_GIT_URL:7}"
  git_folder="${no_scheme##/*/}"

  ANSIBLE_PLAYBOOKS_GIT_PROJECT="${git_folder%.git}"
  ANSIBLE_PLAYBOOKS_PATH="${VENV_PATH}/${ANSIBLE_PLAYBOOKS_GIT_PROJECT}"
  ANSIBLE_PLAYBOOKS_PATH_TMP="${VENV_PATH}/.${ANSIBLE_PLAYBOOKS_GIT_PROJECT}"
}


############################################################
# Help                                                     #
############################################################
HelpCommands() {
  echo "commands:"
  echo "  install           Install ansible to local machine"
  echo "  remove            Remove ansible from local machine"
  echo "  wiki              Show ansible commands examples"
  echo "  update-playbooks  Update local playbooks from git repository"
  echo
}

HelpInstallOptions() {
  echo -e "${RED}IMPORTANT: your local machine should have python3!${NC}"
  echo
  echo "install venv, ansible, playbooks to local machine."
  echo "py venv will be installed to: ${VENV_PATH}"
  echo "ansible will be installed to: ${VENV_PATH}/bin/ansible"
  echo "ansible configs will be installed to: ${ANSIBLE_CFG_PATH}"
  echo "ansible playbooks will be installed to: ${VENV_PATH}/[repo_name: default 're']"
  echo
  echo "venv activate:   source ${VENV_PATH}/bin/activate"
  echo "venv deactivate: deactivate"
  echo
  echo "options:"
  echo "  -r  Set playbooks repository path as https url [https://github.com/mr-chelyshkin/environment.git]"
  echo "  -b  Set playbooks repository branch [master]"
  echo "  -p  Set path to python3 bin file [if not set: try to find python automatically]"
  echo "  -h  Show help"
  echo
}

HelpRemoveOptions() {
  echo "remove installed venv, ansible, playbooks from local machine."
  echo "no magic, just rm ${VENV_PATH}; ${ANSIBLE_CFG_PATH}"
  echo
  echo "options:"
  echo "  -h  Show help"
  echo
}

HelpWikiOptions() {
  echo "show some helpful ansible commands with playbooks (*for: https://github.com/mr-chelyshkin/environment.git)."
  echo
  echo "options:"
  echo "  -h  Show help"
  echo
}

HelpUpdatePlaybookOptions() {
  echo "update ansible playbooks from [-r] option, default: ${ANSIBLE_PLAYBOOKS_GIT_URL}."
  echo "has automatic fix mode: if can't update, try re-clone git repository"
  echo
  echo "options:"
  echo "  -r  Set playbooks repository path as https url [https://github.com/mr-chelyshkin/environment.git]"
  echo "  -b  Set playbooks repository branch [master]"
  echo "  -h  Show help"
  echo
}

HelpUsage() {
  echo "all commands have description:"
  echo "  ${0} [command] -h"
  echo
  echo "examples:"
  echo "  ${0} install"
  echo "  ${0} remove"
  echo "  ${0} wiki"
  echo
  echo "install with predefined python:"
  echo "  ${0} install -p /usr/bin/python3"
  echo
}

HelpAnsible() {
  echo "activate ansible:"
  echo "  source ${VENV_PATH}/bin/activate"
  echo "deactivate ansible:"
  echo "  deactivate"
  echo
  echo "check version:"
  echo "  ansible-playbook --version"
  echo "  ansible --version"
  echo
  echo "usage:"
  echo "ansible-playbook -i hosts osx_mobile_dev.yml"
}


############################################################
# Remove ansible config                                    #
############################################################
RemoveAnsibleConfig() {
  echo "removing ansible configuration file"
  rm -rf "/etc/ansible/ansible.cfg"
  rm -rf "${ANSIBLE_CFG_PATH}"
  rm -rf "${HOME}/.ansible-downloads/"
  echo "ansible configuration file was removed"

  return 0
}


############################################################
# Remove ansible                                           #
############################################################
RemoveAnsible() {
  echo "removing venv ${VENV_PATH}"
  deactivate > /dev/null 2>&1
  rm -rf "${VENV_PATH}"
  echo "ansible and python venv was removed"

  return 0
}


############################################################
# Install ansible                                          #
############################################################
InstallAnsible() {
  if [ -z "${PYTHON_PATH}" ]; then
    PYTHON_PATH=$(command -v python3)
    if [ -z "${PYTHON_PATH}" ]; then
      echo -e "${RED}python3 not found, try use [-p] option for set python3${NC}" >&2
      exit 1
    fi
  else
    if [ ! -f "${PYTHON_PATH}" ]; then
      echo -e "${RED}'${PYTHON_PATH}' is not a file, should by binary python file${NC}" >&2
      exit 1
    fi
  fi

  echo "create venv for ansible: ${VENV_PATH}"
  if "${PYTHON_PATH}" -m venv "${VENV_PATH}"; then
    echo "venv '${VENV_PATH}' was created"
  else
    echo "error while create venv '${VENV_PATH}'" >&2
    return 1
  fi

  echo "update pip:"
  if "${VENV_PATH}/bin/python" -m pip install --upgrade pip; then
    echo "pip was updated"
  else
    echo "error while pip update" >&2
    return 1
  fi

  echo "installing ansible:"
  if "${VENV_PATH}/bin/python" -m pip install ansible; then
    echo "ansible pkg was installed"
  else
    echo "error while pip install ansible" >&2
    return 1
  fi

  return 0
}


############################################################
# Install ansible config                                   #
############################################################
InstallAnsibleConfig() {
  echo "creating configuration file:"

  if ! touch "${ANSIBLE_CFG_PATH}"; then
    echo "error while create ${ANSIBLE_CFG_PATH} file" >&2
    return 1
  fi

  cat << EOF >> "${ANSIBLE_CFG_PATH}"
[defaults]
inventory   = ${ANSIBLE_PLAYBOOKS_PATH}/hosts
roles_path  = ${ANSIBLE_PLAYBOOKS_PATH}/roles

remote_port = 22
sudo_user   = root
timeout     = 10

log_path    = ${VENV_PATH}/ansible.log
nocows      = 1

retry_files_save_path = ${VENV_PATH}/.ansible-retry
host_key_checking = False
EOF

  return 0
}


############################################################
# Clone playbook                                           #
############################################################
ClonePlaybook() {
  GIT_CMD=$(command -v git)
  if [ -z "${GIT_CMD}" ]; then
    echo "git not found, you should install git on your machine and try again" >&2
    return 1
  fi

  url_repo=""
  if [ -z "${GIT_USERNAME}" ] || [ -z "${GIT_PASSWORD}" ]; then
    url_repo=${ANSIBLE_PLAYBOOKS_GIT_URL}
  else
    creds="${GIT_USERNAME}:${GIT_PASSWORD}"
    url_repo="${ANSIBLE_PLAYBOOKS_GIT_URL/\/\////${creds}@}"
  fi

  if [ -d "${VENV_PATH}" ]; then
    cd "${VENV_PATH}" || return 1

    ${GIT_CMD} clone "${url_repo}" -b "${ANSIBLE_PLAYBOOKS_GIT_BRANCH}"
    ret=$?
    if ! test "$ret" -eq 0; then
      echo "error while clone playbooks from ${ANSIBLE_PLAYBOOKS_GIT_URL}" >&2
      return 1
    fi
    return 0
  else
    echo "${VENV_PATH} not found, you should install ansible, use: '${0} install'" >&2
    return 1
  fi

  return 0
}


############################################################
# Fix playbook                                             #
############################################################
FixPlaybook() {
  cd /

  mv "${ANSIBLE_PLAYBOOKS_PATH}" "${ANSIBLE_PLAYBOOKS_PATH_TMP}"
  rm -rf "${ANSIBLE_PLAYBOOKS_PATH}"

  if ClonePlaybook; then
    echo "playbook was fixed"
    rm -rf "${ANSIBLE_PLAYBOOKS_PATH_TMP}"
    return 0
  else
    echo "error while clone playbook, rollback to current state" >&2
    rm -rf "${ANSIBLE_PLAYBOOKS_PATH}"
    mv "${ANSIBLE_PLAYBOOKS_PATH_TMP}" "${ANSIBLE_PLAYBOOKS_PATH}"
    return 1
  fi

  return 0
}


############################################################
# Pull playbook                                            #
############################################################
PullPlaybook() {
  GIT_CMD=$(command -v git)
  if [ -z "${GIT_CMD}" ]; then
    echo "git not found, you should install git on your machine and try again" >&2
    return 1
  fi

  if [ -d "${ANSIBLE_PLAYBOOKS_PATH}" ]; then
    cd "${ANSIBLE_PLAYBOOKS_PATH}" || return 1

    ${GIT_CMD} checkout "${ANSIBLE_PLAYBOOKS_GIT_BRANCH}"

    ${GIT_CMD} fetch --all
    ret=$?
    if ! test "$ret" -eq 0; then
      echo "error while fetch playbooks, try fix it..." >&2
      if FixPlaybook; then
        echo "update playbook local repository was successful"
        return 0
      else
        echo "error while update playbook" >&2
        return 1
      fi
    fi

    ${GIT_CMD} reset --hard HEAD
    ret=$?
    if ! test "$ret" -eq 0; then
      echo "error while reset playbooks, try fix it..." >&2
      if FixPlaybook; then
        echo "update playbook local repository was successful"
        return 0
      else
        echo "error while update playbook" >&2
        return 1
      fi
    fi

    ${GIT_CMD} pull
    ret=$?
    if ! test "$ret" -eq 0; then
      echo "error while pull changes from source" >&2
      if FixPlaybook; then
        echo "update playbook local repository was successful"
        return 0
      else
        echo "error while update playbook" >&2
        return 1
      fi
    fi

    return 0
  fi

  echo -e "${RED}can't find local ${ANSIBLE_PLAYBOOKS_PATH}${NC}" >&2
  echo "perhaps you have non-standard playbooks repository" >&2
  echo "use: '${0} update-playbooks' with option [-r] to select correct playbooks repo" >&2
  return 1
}


############################################################
# Action: Wiki                                             #
############################################################
function Wiki() {
    HelpAnsible
}

############################################################
# Action: Remove                                           #
############################################################
Remove() {
  RemoveAnsibleConfig
  RemoveAnsible

  exit 0
}


############################################################
# Action: UpdatePlaybook                                   #
############################################################
UpdatePlaybook() {
  echo -e "${GREEN}start updating ansible playbooks${NC}"
  if PullPlaybook; then
    echo -e "${GREEN}playbooks updated.${NC}"
    exit 0
  else
    echo -e "${RED}error while update playbooks${NC}" >&2
    exit 1
  fi

  exit 0
}

############################################################
# Action: Install                                          #
############################################################
Install() {
  echo -e "${GREEN}make before install action:${NC}"
  RemoveAnsibleConfig
  RemoveAnsible
  echo -e "${GREEN}before action done.${NC}"

  echo -e "${GREEN}make ansible install:${NC}"
  if InstallAnsible; then
    echo -e "${GREEN}ansible installation done.${NC}"
  else
    echo -e "${RED}error while make ansible install, cleanup starting...${NC}" >&2
    RemoveAnsible
    echo -e "${GREEN}cleanup done.${NC}"
    exit 1
  fi

  echo -e "${GREEN}make ansible config:${NC}"
  if InstallAnsibleConfig; then
    echo -e "${GREEN}ansible configs done.${NC}"
  else
    echo -e "${RED}error while make ansible configuration file, cleanup starting...${NC}" >&2
    RemoveAnsibleConfig
    RemoveAnsible
    echo -e "${GREEN}cleanup done.${NC}"
    exit 1
  fi

  echo -e "${GREEN}make playbooks install:${NC}"
  if ClonePlaybook; then
    echo -e "${GREEN}ansible playbooks done.${NC}"
  else
    echo -e "${RED}error while install playbooks, cleanup starting...${NC}" >&2
    RemoveAnsibleConfig
    RemoveAnsible
    echo -e "${GREEN}cleanup done.${NC}"
    exit 1
  fi

  echo -e "${BLUE}"; HelpAnsible; echo -e "${NC}"
  exit 0
}


############################################################
# Main                                                     #
############################################################
ACTION=${1}

# parse script action.
# shellcheck disable=SC2039
if [[ " ${ACTIONS} " =~ .*\ ${ACTION}\ .* ]]; then
  echo -e "${BLUE}command ${ACTION}${NC}";
else
  echo -e "${RED}command '${ACTION}' not found${NC}" >&2
  echo
  HelpCommands
  HelpUsage
  exit 1
fi
shift

# -- >
if [ "${ACTION}" = "install" ]; then
  # shellcheck disable=SC2039
  while getopts ":hp:r:b:" option; do
    case ${option} in
      h) # display Help
         HelpInstallOptions
         exit 0;;
      p) # python3 binary path
         PYTHON_PATH=${OPTARG};;
      r) # rewrite playbooks repository url
        ANSIBLE_PLAYBOOKS_GIT_URL=${OPTARG};;
      b) # rewrite playbooks repository branch
        ANSIBLE_PLAYBOOKS_GIT_BRANCH=${OPTARG};;
      *) # invalid option
         echo "you set invalid option to script."
         echo "please watch help for correct usage:"
         HelpInstallOptions
         HelpUsage
         exit 1;;
    esac
  done
  SetGitRepositoryEnvs
  Install
elif [ "${ACTION}" = "remove" ]; then
  # shellcheck disable=SC2039
  while getopts ":h" option; do
    case ${option} in
      h) # display Help
         HelpRemoveOptions
         exit 0;;
      *) # invalid option
         echo "you set invalid option to script."
         echo "please watch help for correct usage:"
         HelpRemoveOptions
         HelpUsage
         exit 1;;
    esac
  done
  Remove
elif [ "${ACTION}" = "wiki" ]; then
  # shellcheck disable=SC2039
  while getopts ":h" option; do
    case ${option} in
      h) # display Help
         HelpWikiOptions
         exit 0;;
      *) # invalid option
         echo "you set invalid option to script."
         echo "please watch help for correct usage:"
         HelpWikiOptions
         HelpUsage
         exit 1;;
    esac
  done
  Wiki
elif [ "${ACTION}" = "update-playbooks" ]; then
  # shellcheck disable=SC2039
  while getopts ":hr:b:" option; do
    case ${option} in
      h) # display Help
         HelpUpdatePlaybookOptions
         exit 0;;
      r) # rewrite playbooks repository url
        ANSIBLE_PLAYBOOKS_GIT_URL=${OPTARG};;
      b) # rewrite playbooks repository branch
        ANSIBLE_PLAYBOOKS_GIT_BRANCH=${OPTARG};;
      *) # invalid option
         echo "you set invalid option to script."
         echo "please watch help for correct usage:"
         HelpUpdatePlaybookOptions
         HelpUsage
         exit 1;;
    esac
  done
  SetGitRepositoryEnvs
  UpdatePlaybook
fi

exit 0

