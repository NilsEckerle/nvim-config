# Run from inside packaging/:  make deb && make test
VERSION      ?= 1.0.0
DEBIAN_IMAGE ?= debian:bookworm       # oldest Debian you want to support
TEST_IMAGE   ?= debian:bookworm-slim
DEB           = dist/nvim-bundle_$(VERSION)_amd64.deb

.PHONY: deb test test-shell test-image clean

## Build the .deb inside a Debian container -> packaging/dist/
## Build context is the repo root (..), dockerfile lives here.
deb:
	DOCKER_BUILDKIT=1 docker build \
		-f dockerfile.build \
		--build-arg DEBIAN_IMAGE=$(DEBIAN_IMAGE) \
		--build-arg VERSION=$(VERSION) \
		--target artifact --output dist ..

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
