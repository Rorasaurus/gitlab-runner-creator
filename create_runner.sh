# Creates and configures a Gitlab runner in a Docker container
# -------------------------------------------------------------------------------------
# Author          :   Rory Swann {rory@shirenet.io}
# Version         :   v1.0
# Last Updated    :   2022-01-28
# Notes           :   This script does NOT configure secrets
# -------------------------------------------------------------------------------------
#!/usr/bin/env bash

usage () {
    echo -e "\nUsage:\n"
    echo -e "  $0 -n [runner-name] -d [runner-description] -t [runner-token] -i [default-image] -l [runner-tags]\n"
    echo -e "  - runner-name must not contain spaces and should be lower case."
    echo -e "  - default-image is not required. Defaults to alpine:latest if not set."
    echo -e "  - runner-tags should contain a comma seperated list. They are not required.\n"
}

# Get arguments
while getopts :n:d:t:i:l: options; do
        case $options in
                n) RUNNER_NAME=$OPTARG;;
                d) RUNNER_DESC=$OPTARG;;
                t) RUNNER_TOKEN=$OPTARG;;
                i) RUNNER_IMAGE=$OPTARG;;
                l) RUNNER_TAGS=$OPTARG;;

                ?) usage && exit 1
        esac
done

shift "$(( OPTIND - 1 ))"

if [ -z "$RUNNER_NAME" ] || [ -z "$RUNNER_DESC" ] || [ -z $RUNNER_TOKEN ]; then
        echo 'Missing required argument' >&2
        usage
        exit 1
fi

if [ -z "$RUNNER_IMAGE" ]; then
    echo -e "Default runner image not defined. Using 'alpine:latest'"
    RUNNER_IMAGE="alpine:latest"
fi

# Variables
RUNNER_USER="docker-runner"
GITLAB_SERVER="gitlab.shirenet"
VOLUMES_DIR="/home/${RUNNER_USER}/docker_volumes"
VOLUMES=(".config" "gitlab-runner" ".secrets" ".ssh" ".docker")

# Check the current user is correct
if [ $(whoami) == ${RUNNER_USER} ]; then
    echo "Current user is ${RUNNER_USER}"
else
    echo "Terminating. Current user is $(whoami)"
fi

# Print the details
echo -e "\nBuilding with the following variables:"
echo "Runner name:          $RUNNER_NAME"
echo "Runner description:   $RUNNER_DESC"
echo "Runner image:         $RUNNER_IMAGE"
echo "Runner tags:          $RUNNER_TAGS"
echo -e "Runner token:         $RUNNER_TOKEN\n"

# Check the user is sure
while true
do
    read -r -p '>>> Do you want to continue? ' choice
    case "$choice" in
      n|N) echo "Terminating" && exit 1;;
      y|Y) break;;
      *) echo 'Response not valid';;
    esac
done

# Create the required directory tree
for i in ${VOLUMES[@]}; do
    mkdir -p ${VOLUMES_DIR}/${RUNNER_NAME}/${i}
done

# Start and configure the Docker container containing the gitlab-runner process
sudo docker run -d \
    --name ${RUNNER_NAME} --restart always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v ${HOME}/docker_volumes/${RUNNER_NAME}/gitlab-runner:/etc/gitlab-runner \
    -v ${HOME}/docker_volumes/${RUNNER_NAME}/.config:/root/.config \
    -v ${HOME}/docker_volumes/${RUNNER_NAME}/.docker:/root/.docker \
    -v ${HOME}/docker_volumes/${RUNNER_NAME}/.ssh:/root/.ssh \
    -v ${HOME}/docker_volumes/${RUNNER_NAME}/.secrets:/root/.secrets \
    gitlab/gitlab-runner:latest

# Check the container is running. If so, register it with the Gitlab server
if sudo docker ps | grep $RUNNER_NAME; then
    echo -e "\nRunner deployed successfully. Registering with ${GITLAB_SERVER}"
    sudo docker exec ${RUNNER_NAME} gitlab-runner register --non-interactive --url "${GITLAB_SERVER}" --registration-token "${RUNNER_TOKEN}" --description "${RUNNER_DESC}" --executor "docker" --docker-image "${RUNNER_IMAGE}" --docker-volumes "/var/run/docker.sock:/var/run/docker.sock" --tag-list "${RUNNER_TAGS}"
else
    echo -e "\nSomething went wrong. Please perform manual checks."
fi