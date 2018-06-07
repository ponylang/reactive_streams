BUILD_DIR ?= build
SRC_DIR ?= reactive-streams
SOURCE_FILES := $(shell find $(SRC_DIR) -name \*.pony)
PONYC ?= ponyc
binary_name := test
binary :=$(BUILD_DIR)/$(binary_name)
config ?= release
arch ?=

ifneq ($(config),release)
	PONY_FLAGS += --debug
endif

ifneq ($(arch),)
	PONY_FLAGS += --cpu $(arch)
endif

$(binary): $(SOURCE_FILES) | $(BUILD_DIR)
	${PONYC} $(PONYC_FLAGS) $(SRC_DIR) -o ${BUILD_DIR} -b $(binary_name)

test: $(binary)
	$(binary)

clean:
	rm -rf $(BUILD_DIR)

$(BUILD_DIR)/spl4:
	${PONYC} $(PONYC_FLAGS) examples/spl4 -o ${BUILD_DIR} -b spl4

examples: $(BUILD_DIR)/spl4

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

.PHONY: clean
