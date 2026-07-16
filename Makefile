.PHONY: lint syntax-check clean

lint:
	ansible-lint

yamllint:
	yamllint --strict .

syntax-check:
	for pb in playbooks/*.yml; do \
		ansible-playbook --syntax-check "$$pb"; \
	done

all: lint yamllint syntax-check

clean:
	rm -rf .retry *.retry
