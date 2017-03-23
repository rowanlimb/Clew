CURRENT_DIRECTORY := $(shell pwd)

help:
	@echo "Docker Compose Help"
	@echo "-----------------------"
	@echo ""
	@echo "Build and start:"
	@echo "    make begin"
	@echo ""
	@echo "Stop:"
	@echo "    make stop"
	@echo ""
	@echo "Really, really start over:"
	@echo "    make clean"
	@echo ""
	@echo "See contents of Makefile for more targets."

begin: build start

./tmp:
	@mkdir -p ./tmp

./tmp/authorizedkeys: ./tmp/id_rsa.pub
	@cp ./tmp/id_rsa.pub ./tmp/authorized_keys

./tmp/id_rsa.pub: ./tmp
	@ssh-keygen -f ./tmp/id_rsa -t rsa -N ''
	
runjob: 
	@docker exec -u docker hive-server /bin/bash -c 'cd /home/docker;source .bashrc;./test_mr/runJob'

start:
	@docker-compose up -d

stop:
	@docker-compose stop

status:
	@docker-compose ps

restart: stop start

clean: stop
	@docker-compose down

build: ./tmp/authorizedkeys
	@export USERID=$$(id -u); docker-compose build

tail:
	@docker-compose logs -f


.PHONY: begin runJob start stop status restart clean build tail
