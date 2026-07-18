.PHONY: verify

verify:
	bash scripts/verify_harness_source.sh
	bash tests/source_verify_contract_test.sh
