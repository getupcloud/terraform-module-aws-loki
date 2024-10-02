VERSION:=1.4

test: fmt init validate

i init:
	terraform init

v validate:
	terraform validate

f fmt:
	terraform fmt

release:
	@if [ $$(git status --short | wc -l) -gt 0 ]; then \
		git status; \
		echo ; \
		echo "Tree is not clean. Please commit and try again"; \
		exit 1; \
	fi
	git pull origin main --tags
	git tag v$(VERSION)
	git push origin main --tags
	git push origin main
