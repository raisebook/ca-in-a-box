NAME = docker.brutalbits.com/joffotron/ca-in-a-box
VERSION = 1

all: build tag_latest

build:
	docker build -t $(NAME):$(VERSION) .

tag_latest:
	docker tag $(NAME):$(VERSION) $(NAME):latest

push:
	docker push $(NAME):$(VERSION)
	docker push $(NAME):latest

run:
	docker run -it --rm -v `pwd`/config/:/root/cfg  $(NAME):$(VERSION)

clean:
	docker rmi $(NAME):$(VERSION)
