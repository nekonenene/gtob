COMMAND_NAME   = gtob
BIN_PATH       = /usr/local/bin
CURRENT_DIR    = $(shell pwd)
TMP_REPOS_PATH = $(HOME)/.$(COMMAND_NAME)-tmp

.PHONY: install uninstall

install:
	@echo "install \"$(COMMAND_NAME)\" command..."
	@install -m 755 $(CURRENT_DIR)/$(COMMAND_NAME).sh $(BIN_PATH)/$(COMMAND_NAME)
	@chmod +x $(BIN_PATH)/$(COMMAND_NAME)
	@echo "installation completed!"

uninstall:
	@echo "remove \"$(COMMAND_NAME)\" command..."
	@rm -f $(BIN_PATH)/$(COMMAND_NAME)
	@read -p "remove \"$(TMP_REPOS_PATH)\" directory? [y/n]" -n 1 -r CHOICE; \
		echo; \
		if [ "$$CHOICE" == "y" -o "$$CHOICE" == "Y" ]; then \
			echo "remove \"$(TMP_REPOS_PATH)\" directory..."; \
			rm -rf $(TMP_REPOS_PATH); \
		fi
	@echo "uninstallation completed!"
