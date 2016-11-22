all: build load run save

build:
	docker-compose build

push:
	docker.brutalbits.com/joffotron/ca-in-a-box:latest

load:
# 	aws s3 cp "s3://${CA_BUCKET}/root-ca.tar" ./root-ca.tar
# 	docker

save:

run:
	docker-compose run --rm ca_in_a_box

clean:
	docker rmi docker.brutalbits.com/joffotron/ca-in-a-box:latest
