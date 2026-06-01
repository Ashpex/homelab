GOCACHE ?= /private/tmp/go-build
GOMODCACHE ?= /private/tmp/go-mod

export GOCACHE
export GOMODCACHE

.PHONY: preview up refresh destroy test

test:
	go test ./...

preview:
	pulumi preview

up:
	pulumi up

refresh:
	pulumi refresh

destroy:
	pulumi destroy
