# Run from inside packaging/:  make deb && make test
VERSION      ?= 1.0.0
DEBIAN_IMAGE ?= debian:trixie        # oldest Debian you want to support
TEST_IMAGE   ?= debian:trixie-slim
DEB           = dist/nvim-bundle_$(VERSION)_amd64.deb

.PHONY: deb test test-shell test-image clean

## Build the .deb inside a Debian container -> packaging/dist/
## Build context is the repo root (..), dockerfile lives here.
## Requires the docker-buildx plugin (pacman -S docker-buildx).
deb:
	DOCKER_BUILDKIT=1 docker build \
		-f dockerfile.build \
		--build-arg DEBIAN_IMAGE=$(DEBIAN_IMAGE) \
		--build-arg VERSION=$(VERSION) \
		--target artifact --output dist ..

## Same result without the buildx plugin: build the 'build' stage as a normal
## image, then copy the .deb out of a throwaway container.
deb-nobuildx:
	DOCKER_BUILDKIT=1 docker build \
		-f dockerfile.build \
		--build-arg DEBIAN_IMAGE=$(DEBIAN_IMAGE) \
		--build-arg VERSION=$(VERSION) \
		--target build -t nvim-bundle-build ..
	mkdir -p dist
	cid=$$(docker create nvim-bundle-build); \
	docker cp $$cid:/dist/. dist/; \
	docker rm $$cid

test-image:
	docker build -f dockerfile.test \
		--build-arg DEBIAN_IMAGE=$(TEST_IMAGE) \
		-t nvim-bundle-test .

## Automated offline smoke test (no network in the container)
test: test-image
	docker run --rm --network none -v $$(pwd)/dist:/dist:ro nvim-bundle-test bash -c '\
		set -e; \
		dpkg -i /dist/*.deb; \
		nvim --version | head -n1; \
		su - dev -c "nvim-bundle-setup"; \
		su - dev -c "nvim --headless +q"; \
		echo SMOKE-TEST-OK'

## Interactive offline test: installs the deb, drops you into a shell as "dev"
test-shell: test-image
	docker run -it --rm --network none -v $$(pwd)/dist:/dist:ro nvim-bundle-test bash -c '\
		dpkg -i /dist/*.deb && su - dev'

clean:
	rm -rf dist
	-docker rmi nvim-bundle-test
