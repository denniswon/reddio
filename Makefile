.PHONY: all
all: build
FORCE: ;

SHELL  := env LIBRARY_ENV=$(LIBRARY_ENV) $(SHELL)
LIBRARY_ENV ?= dev

BIN_DIR = $(PWD)/bin

$(info LIBRARY_ENV: $(LIBRARY_ENV))
$(info BIN_DIR: $(BIN_DIR))

.PHONY: build

clean:
	rm -rf bin/*

dependencies:
	curl -sSfL https://raw.githubusercontent.com/cosmtrek/air/master/install.sh | sh -s
	go mod download

build: dependencies build-api build-cmd

build-api:
	go build -tags $(LIBRARY_ENV) -o ./bin/api api/main.go

build-cmd:
	go build -tags $(LIBRARY_ENV) -o ./bin/search cmd/main.go

linux-binaries:
	CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -tags "$(LIBRARY_ENV) netgo" -installsuffix netgo -o $(BIN_DIR)/api api/main.go
	CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -tags "$(LIBRARY_ENV) netgo" -installsuffix netgo -o $(BIN_DIR)/search cmd/main.go

ci: dependencies test

serve-api: ./$(BIN_DIR)/api

serve-cmd: ./$(BIN_DIR)/search

build-mocks:
	@go get github.com/golang/mock/gomock
	@go install github.com/golang/mock/mockgen
	@~/go/bin/mockgen -source=module/user/interface.go -destination=module/user/mock/user.go -package=mock

test:
	go test -tags testing ./...

fmt: ## gofmt and goimports all go files
	find . -name '*.go' -not -wholename './vendor/*' | while read -r file; do gofmt -w -s "$$file"; goimports -w "$$file"; done

.PHONY: dev

build-dev:
	go build -tags dev -o ./tmp/api api/main.go

dev:
	@go get -u github.com/cosmtrek/air
	./bin/air -c .air.toml
