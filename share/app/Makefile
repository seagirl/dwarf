all:

test:
	env DWARF_TEST_LEVEL=0 prove -PPretty -prlv t
jenkins:
	env DWARF_TEST_LEVEL=0 JUNIT_OUTPUT_FILE=result.xml prove -rl --harness TAP::Harness::JUnit --merge t
