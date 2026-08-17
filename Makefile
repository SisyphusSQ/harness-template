.PHONY: verify

verify:
	bash scripts/verify_harness_source.sh
	bash tests/source_verify_contract_test.sh
	bash tests/target_check_contract_test.sh
	bash tests/policy_contract_test.sh
