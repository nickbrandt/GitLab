PREFIX=/usr/local
VERSION=$(shell git describe)-$(shell date -u +%Y%m%d.%H%M%S)

gitlab-git-http-server: main.go
	go build -ldflags "-X main.Version ${VERSION}" -o gitlab-git-http-server main.go
