###
# Tool building
###

SHELL=/bin/bash

#.PHONY:
.DEFAULT_GOAL := dev

registry_host = localhost:5000
repo_location = /repos/tool_scaffold
image = term
tag = latest

# Test the tool locally
build:
	docker build -t $(image):$(tag) .

dev: build
	docker run \
	-v `pwd`/src/:/home/ubuntu/src \
    -v `pwd`/etc/:/home/ubuntu/etc \
    -v /pbi/:/pbi/ \
    -it $(image):$(tag)

# Develop inside container environment
# The src/ and etc/ folders are mounted into the container
# Changes made on host propagate into container
dev_bash: build
	docker run --entrypoint=/bin/bash \
	-v `pwd`/src/:/home/ubuntu/src \
    -v `pwd`/etc/:/home/ubuntu/etc \
    -v /pbi/:/pbi/: \
    -it $(image):$(tag)

# Build singularity image for production
vagrant_up:
	vagrant up

ssh:
	vagrant ssh

vagrant_halt:
	vagrant halt

vm_docker_registry: vagrant_up
	vagrant ssh -c "/bin/bash $(repo_location)/etc/start_registry.sh"

vm_docker_build: vagrant_up
	vagrant ssh -c "cd $(repo_location) && docker build -t $(image):$(tag) ."
	vagrant ssh -c "docker tag $(image):$(tag) $(registry_host)/$(image):$(tag)"

vm_docker_push: vm_docker_registry
	vagrant ssh -c "docker push $(registry_host)/$(image):$(tag)"

vm_singularity_build: vm_docker_push
	mkdir -p simg
	vagrant ssh -c "singularity build --nohttps $(repo_location)/simg/$(image).simg docker://$(registry_host)/$(image):$(tag)"
	vagrant ssh -c "docker ps -q --filter ancestor="registry" | xargs -r docker stop"

vm_simg_test:
	vagrant ssh -c "cp $(repo_location)/simg/$(image).simg ~/ && ./$(image).simg"
	vagrant ssh -c "rm ~/$(image).simg"
