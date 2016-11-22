all: build run

build:
	docker-compose build

push:
	docker tag ca-in-a-box:latest docker.brutalbits.com/joffotron/ca-in-a-box:latest
	docker push docker.brutalbits.com/joffotron/ca-in-a-box:latest

run:
	docker-compose run --rm ca_in_a_box

export_root:
	docker-compose run --rm ca_in_a_box /usr/local/bin/export-root.sh

clean:
	docker rmi docker.brutalbits.com/joffotron/ca-in-a-box:latest
