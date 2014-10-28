#!/bin/bash
set -e

# command boilerplate code
BASE_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )/../" && pwd )"
CMD_PATH="${BASH_SOURCE[0]}"
source $BASE_PATH/lstack.sh
source $BASE_PATH/install/creds.sh

main(){

  if ! [ -f "$deploy_file" ]; then
    usage
    exit 1
  fi

  file "$deploy_file" | grep "QCOW Image" > /dev/null 2>&1 || {
    error "Invalid image. Only QCOW images supported for now."
    exit 1
  }

  image_name=$(basename $deploy_file)

  source $BASE_PATH/commands/bootstrap.sh -q
  source $BASE_PATH/commands/importimg.sh "$deploy_file"

  info "Deploying $deploy_name..."
  info "Instance name:   $deploy_name"
  info "Instance flavor: $deploy_flavor"

  source $BASE_PATH/commands/nova.sh boot \
                                      --image "$image_name" \
                                      --flavor $deploy_flavor \
                                      "$deploy_name"
}

columnize() {
  echo $@ | awk -F, '{ printf "%-20s %-40s\n", $1, $2}'
}

usage() {
  echo "Usage: lstack deploy [options] <image-file>"
  echo
  echo FLAGS
  echo
  columnize "--name",      "Instance name   (default: lstack-%timestamp)"
  columnize "--flavor",    "Instance flavor ('lstack nova flavor-list' to list)"
  columnize "--file",      "QCOW2 image to deploy (required)"
  echo
}

needs_root

deploy_name=lstack-$(date +%s)
deploy_flavor="m1.tiny"
deploy_file=

deploy_option_name()   ( deploy_name="$1"; shift; dispatch deploy "$@" )
deploy_option_flavor() ( deploy_flavor="$1"; shift; dispatch deploy "$@" )
deploy_option_file()   ( deploy_file="$1"; shift; dispatch deploy "$@" )
deploy_option_help()   ( usage; )
deploy_command_help()  ( usage; )
deploy_ () ( main )

dispatch deploy "$@"
