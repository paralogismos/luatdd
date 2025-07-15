# Makefile for luatdd
.POSIX:

EXEC=luatdd
EXT=sh
SRC_FILE=$(EXEC).$(EXT)

# Default installation directory.
INSTALL_DIR=$(HOME)/bin
INSTALL_PATH=$(INSTALL_DIR)/$(EXEC)

# luatdd.lua module code.
LUA_MOD=luatdd.lua
LUA_DIR=/usr/local/lib/lua/5.4
LUA_LIB=$(LUA_DIR)/$(LUA_MOD)

# Uninstall record.
UNINST=Uninstall

.PHONY: install reinstall uninstall
install:
	@cp $(SRC_FILE) $(INSTALL_PATH)
	@printf "%s\n" $(INSTALL_PATH) > $(UNINST)
	@chmod +x $(INSTALL_PATH)  # Set executable permissions
	@sudo cp $(LUA_MOD) $(LUA_LIB)
	@printf "%s\n" $(LUA_LIB) >> $(UNINST)
	@chmod 0444 $(UNINST)      # Make uninstall record read-only
	@echo $(EXEC) installed in $(INSTALL_DIR).
	@echo $(LUA_MOD) installed in $(LUA_DIR).

reinstall:
	@sudo xargs rm -f < $(UNINST)
	@rm -f $(UNINST)
	@cp $(SRC_FILE) $(INSTALL_PATH)
	@printf "%s\n" $(INSTALL_PATH) > $(UNINST)
	@chmod +x $(INSTALL_PATH)  # Set executable permissions
	@sudo cp $(LUA_MOD) $(LUA_LIB)
	@printf "%s\n" $(LUA_LIB) >> $(UNINST)
	@chmod 0444 $(UNINST)      # Make uninstall record read-only
	@echo $(EXEC) reinstalled in $(INSTALL_DIR).
	@echo $(LUA_MOD) reinstalled in $(LUA_DIR).

uninstall:
	@sudo xargs rm -f < $(UNINST)
	@rm -f $(UNINST)
	@echo $(EXEC) has been uninstalled.
	@echo $(LUA_MOD) has been uninstalled.

