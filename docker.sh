#!/bin/bash
#
# Helper script to build and run the docker container.
# 
#
# BUILD IMAGE:
#
#   ./docker -b
#
#
# RUN CONTAINER:
#
#   Run the ./build.sh script inside of the container
#   ./docker -r ./build.sh
#
#   Run the container and drop into a shell
#   ./docker -r
#
#

DOCKER_IMAGE_TAG=arctica-os-builder
DOCKER_CONTAINER_NAME=${DOCKER_IMAGE_TAG}-container

WORK_DIR="${PWD}/work"
BUILDER_DIR="${PWD}/builder"

function help() {
    echo -e "\nUsage:\n"
    echo -e "   ./docker.sh -b"
    echo -e "   ./docker.sh -r [optional arguments]"
    echo -e "\nOptions:\n"
    echo -e "   -b --Build the docker image."
    echo -e "   -r --Run the docker container (remianing parameters will be passed to the docker container command)."
    echo -e "   -h --Displays this help message."
    echo -e "\nExamples:\n"
    echo -e "   Build Image:"
    echo -e "   ./docker -b\n"
    echo -e "   Run './build.sh' inside of the container:"
    echo -e "   ./docker -r ./build.sh\n"
    echo -e "   Run the container and drop into a shell:"
    echo -e "   ./docker -r"
    echo -e ""
}

# process options
while getopts brh OPTIONS; do
  case $OPTIONS in
    b)
      # do docker build
      BUILD=1
      ;;
    r)
      # do docker run
      RUN=1
      ;;
    h)
      help
      exit 0
      ;;
    \?) #unrecognized option - show help
      echo -e \\n"Option -$OPTIONS not allowed."
      help
      exit 1
      ;;
  esac
done


# Shift past the last option parsed by getopts
shift $((OPTIND-1))
# now $@ has everything after the options

if [[ "${BUILD}" == "1" ]]; then

    docker build --tag "${DOCKER_IMAGE_TAG}" \
                --build-arg "USER=$(whoami)" \
                --build-arg "host_uid=$(id -u)" \
                --build-arg "host_gid=$(id -g)" \
                -f "${DOCKERFILE}" \
                .
elif [[ "${RUN}" == "1" ]]; then

    if [[ ! -d "$WORK_DIR" ]]; then
        echo "WORK_DIR=${WORK_DIR} does not exits. Creating.."
        mkdir ${WORK_DIR}
    fi

    # run the docker image
    #   --rm  automatically removes the container and on exit
    #   -i  keeps the standard input open
    #   -t  provides a terminal as a interactive shell within container
    #   -v  are file systems mounted on docker container to preserve data
    #       generated during the build and these are stored on the host.
    docker run -it --rm --privileged --name "${DOCKER_CONTAINER_NAME}" \
        -v "${WORK_DIR}":/home/${USER}/work \
        -v "${BUILDER_DIR}":/home/${USER}/builder \
        "${DOCKER_IMAGE_TAG}" \
        "$@"

else

    echo "Missing command options."
    help
    exit 1

fi


