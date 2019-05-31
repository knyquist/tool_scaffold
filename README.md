# Tool Scaffold

This repo contains the bones of a convention for developing and deploying an analysis tool
inside a container. This is useful, because the runtime environment can be controlled and
isolated from the environment in which the tool is run.

Docker is used for local development, local testing, and local execution. For production deployment,
the docker image is compiled into a singularity image file. Singularity is often installed on HPC nodes.
Singularity images can be run as executables.

## Installation

This repo is currently geared towards local development on a Mac. Singularity does not work on macs, so
you have to do some funny business with virtual machines to simulate a linux environment.
You need virtualbox and vagrant [installed](https://sourabhbajaj.com/mac-setup/Vagrant/README.html).
```aidl
brew update
brew cask install virtualbox
brew cask install vagrant
brew cask install vagrant-manager 
``` 

If you're using linux natively, you don't have to do this. However, currently the Makefile uses
`vagrant ssh -c` to execute "remote" commands inside the vm. It doesn't yet have the conditional logic
to not do that when running on native linux boxes.

You'll need to edit the piece of the Vagrant file that sets the config.vm.synced_folder. These are
user specific.

You'll also need [docker](https://docs.docker.com/docker-for-mac/install/), both on your host machine as 
well as inside the vm. I haven't automated the installation of docker inside the vm yet. The /pbi drives
are mounted into the containers, so that Pacbio data is accessible. Since these are NFS volumes, you must
add them to docker via Preferences -> File Sharing.

Aside: I created a script to automount the pbi drives using the nfs protocol. The repo is 
[here](http://bitbucket.pacificbiosciences.com:7990/users/knyquist/repos/mountpbidrives/browse). I
recommend using that script on your machine, or employing some alternative. I have the script executed
every time the computer is booted and I have it aliased to `mountpbi` in my .bash_profile. See that repo's
README for more information.

## Usage

This scaffold comprises a fully functional tool that can be built and executed. The tool's logic is wrapped
within `src/main.py`. In this scaffold/toy case, the tool prints 'hello world!' to the console.

### Development

A local (dev) version of the tool can be tested with `make dev`. You should see output that looks like
```aidl
knyquist@knyquist-mac.nanofluidics.com:~/repos/tool_scaffold$ make dev
docker build -t term:latest .
Sending build context to Docker daemon  178.8MB
Step 1/13 : FROM ubuntu:18.04
 ---> 7698f282e524
Step 2/13 : RUN apt-get update &&     apt-get install -y sudo vim nano curl git build-essential libreadline-dev             zlib1g-dev libssl1.0-dev libbz2-dev libsqlite3-dev libffi-dev jq
 ---> Using cache
 ---> 4220cca1d6ab
Step 3/13 : RUN mkdir -p /pbi/dept /pbi/collections /pbi/analysis
 ---> Using cache
 ---> b3c183144d6b
Step 4/13 : ENV username ubuntu
 ---> Using cache
 ---> ae077a3e4a95
Step 5/13 : RUN useradd -rm -d /home/ubuntu -s /bin/bash -g root -G sudo -u 1000 ${username}
 ---> Using cache
 ---> 1233cc8f751c
Step 6/13 : WORKDIR /home/${username}
 ---> Using cache
 ---> 3e2c163feac9
Step 7/13 : RUN chown -R ubuntu /pbi
 ---> Using cache
 ---> afcf273cf79b
Step 8/13 : ENV PYENV_ROOT="/home/${username}/.pyenv"     PATH="/home/${username}/.pyenv/shims:/root/.pyenv/bin:${PATH}"     PIPENV_YES=1     PIPENV_DONT_LOAD_ENV=1     LC_ALL="C.UTF-8"     LANG="en_US.UTF-8"
 ---> Using cache
 ---> a52e8dfa9818
Step 9/13 : RUN curl -L https://raw.githubusercontent.com/yyuu/pyenv-installer/master/bin/pyenv-installer | bash     && /home/${username}/.pyenv/bin/pyenv install 2.7.8 && /home/${username}/.pyenv/bin/pyenv global 2.7.8     && /home/${username}/.pyenv/bin/pyenv rehash && pip install --upgrade pip
 ---> Using cache
 ---> 26fd1bd7c454
Step 10/13 : ADD src/ /home/${username}/src
 ---> Using cache
 ---> b6185c0faebb
Step 11/13 : ADD etc/ /home/${username}/etc
 ---> Using cache
 ---> 32a7200d00c8
Step 12/13 : USER ${username}
 ---> Using cache
 ---> e0123db6bcf8
Step 13/13 : ENTRYPOINT ["python", "src/main.py"]
 ---> Using cache
 ---> 46ae93ede428
Successfully built 46ae93ede428
Successfully tagged term:latest
docker run \
	-v `pwd`/src/:/home/ubuntu/src \
    -v `pwd`/etc/:/home/ubuntu/etc \
    -v /pbi/:/pbi/ \
    -it term:latest
hello world!
```
To develop the tool, you can use `make dev_bash`. This will dump you into a bash prompt inside the
container. It mounts etc/ to /home/ubuntu/etc (container) and src/ to /home/ubuntu/src (container). 
The /pbi (host) drives are mounted to /pbi (container) as well. Any changes you make within the
mounted volumes (such as changes to source code!) will be instantly propagated inside, without the need
to rebuild the container. 

### Production deployment

Tools can be compiled into singularity images by calling `make vm_docker_build` followed by 
`make vm_singularity_build`. This puts an image file in the simg/ directory. You can test that the toy
image functions with `make vm_simg_test`. Remember, you can't directly call the executable on your mac,
since singularity doesn't work. However, they should work on an HPC node.
