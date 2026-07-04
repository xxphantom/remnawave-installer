# Main variables
BUILD_DIR = dist
SRC_DIR = src
LIB_DIR = $(SRC_DIR)/lib
MODULES_DIR = $(SRC_DIR)/modules
SHELL = /bin/bash

# Result file name
TARGET = install_remnawave.sh

# Language files
LANG_DIR = $(SRC_DIR)/lang
LANG_FILES = $(LANG_DIR)/en.sh $(LANG_DIR)/ru.sh

# List of all modules in the order of inclusion
MODULES = $(LIB_DIR)/constants.sh \
          $(LIB_DIR)/i18n.sh \
          $(LANG_DIR)/en.sh \
          $(LANG_DIR)/ru.sh \
          $(LIB_DIR)/system.sh \
          $(LIB_DIR)/containers.sh \
          $(LIB_DIR)/display.sh \
          $(LIB_DIR)/input.sh \
          $(LIB_DIR)/network.sh \
          $(LIB_DIR)/crypto.sh \
          $(LIB_DIR)/http.sh \
          $(LIB_DIR)/remnawave-api.sh \
          $(LIB_DIR)/config.sh \
          $(LIB_DIR)/validation.sh \
          $(LIB_DIR)/misc.sh \
          $(LIB_DIR)/vless.sh \
          $(LIB_DIR)/generate-selfsteal.sh \
		  $(MODULES_DIR)/tools/run-cli.sh \
		  $(MODULES_DIR)/tools/enable-bbr.sh \
		  $(MODULES_DIR)/tools/show-credentials.sh \
		  $(MODULES_DIR)/tools/panel-access.sh \
		  $(MODULES_DIR)/tools/update.sh \
		  $(MODULES_DIR)/tools/warp-docker-integration.sh \
		  $(MODULES_DIR)/tools/view-logs.sh \
          $(MODULES_DIR)/auth/full-auth.sh \
		  $(MODULES_DIR)/auth/cookie-auth.sh \
          $(MODULES_DIR)/auth/static-site.sh \
          $(MODULES_DIR)/subscription-page.sh \
          $(MODULES_DIR)/panel/vless-config.sh \
          $(MODULES_DIR)/panel/caddy-cookie-auth.sh \
          $(MODULES_DIR)/panel/caddy-full-auth.sh \
          $(MODULES_DIR)/panel/setup.sh \
          $(MODULES_DIR)/node/selfsteal.sh \
          $(MODULES_DIR)/node/node.sh \
          $(MODULES_DIR)/all-in-one/vless-config.sh \
          $(MODULES_DIR)/all-in-one/setup-node.sh \
          $(MODULES_DIR)/all-in-one/caddy-cookie-auth.sh \
          $(MODULES_DIR)/all-in-one/caddy-full-auth.sh \
					$(MODULES_DIR)/all-in-one/setup.sh

.PHONY: all
all: clean build

# Create build directory
$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

# Build script
.PHONY: build
build: $(BUILD_DIR)
	@echo "Building Remnawave installer..."
	@# Remove previous build if it exists
	@rm -f $(BUILD_DIR)/$(TARGET)
	@echo '#!/bin/bash' > $(BUILD_DIR)/$(TARGET)
	@echo '' >> $(BUILD_DIR)/$(TARGET)
	@echo '# Remnawave Installer ' >> $(BUILD_DIR)/$(TARGET)
	@echo '' >> $(BUILD_DIR)/$(TARGET)

	@# Add module contents, removing shebang from each file.
	@# NOTE: comment stripping removes lines starting with '#' in column 0 only.
	@# Heredoc content lines must never start with '#' in column 0 (CSS #id,
	@# Caddyfile/YAML comments, etc.) or they will be silently dropped from the build.
	@for module in $(MODULES); do \
		echo "# Including module: $$(basename $$module)" >> $(BUILD_DIR)/$(TARGET); \
		tail -n +2 $$module | grep -v '^#' >> $(BUILD_DIR)/$(TARGET); \
		echo '' >> $(BUILD_DIR)/$(TARGET); \
	done

	@# Add main.sh
	@tail -n +2 $(SRC_DIR)/main.sh | grep -v '^#' >> $(BUILD_DIR)/$(TARGET)

	@# Make script executable
	@chmod +x $(BUILD_DIR)/$(TARGET)
	@echo "Installer successfully built: $(BUILD_DIR)/$(TARGET)"

# Clean
.PHONY: clean
clean:
	@rm -rf $(BUILD_DIR)
	@echo "Build directory cleaned."

# Install
.PHONY: install
install: all
	@echo "Copying script to /usr/local/bin..."
	@sudo cp $(BUILD_DIR)/$(TARGET) /usr/local/bin/$(TARGET)
	@sudo chmod +x /usr/local/bin/$(TARGET)
	@echo "Installation completed. Run '$(TARGET)' to install Remnawave."

# Testing
.PHONY: test
test: all
	@echo "Checking script syntax..."
	@bash -n $(BUILD_DIR)/$(TARGET)
	@echo "Script syntax is correct."

# Debug
.PHONY: debug
debug: all
	@echo "Running in debug mode..."
	@bash -x $(BUILD_DIR)/$(TARGET)
