DEPLOY_LOCATION=../jmcph4.github.io

.DEFAULT_GOAL := build

.PHONY: build
build:
	jekyll build

.PHONY: run
run:
	jekyll serve

.PHONY: publish
publish:
	jekyll build
	rm $(DEPLOY_LOCATION)/* && cp _site/* $(DEPLOY_LOCATION) -r && cd $(DEPLOY_LOCATION) && git add . && git commit -m "Add `date --iso-8601=seconds`"

.PHONY: clean
clean:
	rm _site -rf
