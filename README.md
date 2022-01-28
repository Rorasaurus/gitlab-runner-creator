# Gitlab Runner Creator

This project contains a BASH script to facilitate the creation of a Docker Gitlab runner.

## Usage

This assumes you've already deployed a server to host the Gitlab runners and configured and installed Docker.

The script can run from anywhere, but I'd suggest copying it to the home directory of a dedicated
user. This user will require permission to execute the 'docker' command.

It will create a series of directories to be used as Docker volumes. By default it will create:
* /home/user/docker_volumes/                                ### Directory to store volumes 
* /home/user/docker_volumes/[runner-name]/gitlab-runner     ### Volume stores Gitlab runner config directory
* /home/user/docker_volumes/[runner-name]/.config           ### Generic store for standard Linux .config
* /home/user/docker_volumes/[runner-name]/.docker           ### Store for Docker config
* /home/user/docker_volumes/[runner-name]/.ssh              ### Store for ssh keys required by runner
* /home/user/docker_volumes/[runner-name]/.secrets          ### Store for secrets required by runner

I'd advice against storing your secrets and ssh keys this way, but it's there if you want it. Consider
using something like Hashicorp Vault instead.

Execute the script in the folling way:
```
./create_runner.sh -s [gitlab-server] -n [runner-name] -d [runner-description] -t [runner-token] -i [default-image] -l [runner-tags]
```
* -s [gitlab-server]        ### The address of your Gitlab server.
* -n [runner-name]          ### The name of your Gitlab runner.
* -d [runner-description]   ### Description of your runner.
* -t [runner-token]         ### The token to register your runner.
* -i [default-image]        ### The default image for your runner. Defaults to alpine:latest if not defined.
* -l [runner-tags]          ### The tags to apply to your runner. Provide a comma seperated list if required.

## Trouble shooting

Don't forget to make the script executable by running:
```
chmod +x create_runner.sh
```

Make sure the user running this script is in the 'docker' group:
```
usermod -G docker username
```