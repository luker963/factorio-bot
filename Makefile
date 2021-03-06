include config.mk

EXE=bot
COMMONOBJECTS=factorio_io.o rcon.o area.o pathfinding.o defines.o action.o mine_planning.o inventory.o scheduler.o goal.o entity.o gui/gui.o logging.o # objects used for $(EXE)

ALLTESTS=test/worldlist test/scheduler

# all objects, including those for other targets (i.e. rcon-client)
ALLOBJECTS=$(COMMONOBJECTS) main.o rcon-client.o $(addsuffix .o,$(ALLTESTS))
DEBUG=1


MODNAME=Windfisch_0.0.1
MODSRCS=$(addprefix luamod/$(MODNAME)/,control.lua data.lua info.json prototypes/.emptydir)



DEBUGFLAGS = -O2 -g -D_GLIBCXX_DEBUG -fsanitize=undefined,address
FASTFLAGS = -O2 -g
CXXFLAGS_BASE = -std=c++17
CFLAGS_BASE = -std=c99

GUIFLAGS = -O2

COMPILER ?= GCC
ifeq ($(COMPILER),GCC)
	CC=gcc
	CXX=g++
	WARNFLAGS=-Wall -Wextra -pedantic
	WARNFLAGS+=-Werror=return-type -Werror=implicit-fallthrough
	GUIFLAGS += 
else
	CC=clang
	CXX=clang++
	WARNFLAGS=-Weverything -pedantic -Wno-c++98-compat -Wno-c++98-compat-pedantic -Wno-c++98-c++11-compat -Wno-sign-conversion -Wno-sign-compare -Wno-padded -Wno-exit-time-destructors -Wno-global-constructors -Wno-weak-vtables -Wno-switch-enum -Wswitch -Wno-double-promotion -Wno-documentation-unknown-command -Wno-covered-switch-default
	WARNFLAGS+=-Werror=return-type -Werror=header-hygiene -Werror=implicit-fallthrough
	# -Wswitch-enum complains, even if there's a default: label. -Wswitch does not.
	GUIFLAGS += 
endif


DEBUG ?= 1
ifeq ($(DEBUG),1)
	FLAGS += $(DEBUGFLAGS)
else
	FLAGS += $(FASTFLAGS)
endif

FLAGS += $(WARNFLAGS)
CFLAGS = $(shell fltk-config --cflags --use-images) $(CFLAGS_BASE) $(FLAGS)
CXXFLAGS = $(shell fltk-config --cxxflags --use-images) $(CXXFLAGS_BASE) $(FLAGS)
LINK=$(CXX)
LINKFLAGS=$(CXXFLAGS)
LIBS=$(shell fltk-config --ldflags --use-images)

MODDESTS=$(MODSRCS:luamod/%=$(FACTORIODIR)/mods/%)

# Pseudotargets
.PHONY: all clean run info mod help test build_tests run_tests

all: compile_commands.json $(EXE) rcon-client

clean:
	rm -f $(EXE) $(ALLOBJECTS) $(ALLOBJECTS:.o=.d)
distclean: clean
	rm -f depend compile_commands.json

test: build_tests run_tests
build_tests: $(ALLTESTS)
run_tests: $(addsuffix .run,$(ALLTESTS))

test/%.run: test/%
	@./$< > $@.out
	@if ! diff -u $@.desired $@.out; then echo "TEST $@ FAILED, see above"; false; else echo "TEST $@ PASSED"; true; fi

test/worldlist: $(COMMONOBJECTS) test/worldlist.o
	$(LINK) $(LINKFLAGS) $(LDFLAGS) $^ $(LIBS) -o $@

test/scheduler: $(COMMONOBJECTS) test/scheduler.o scheduler.o
	$(LINK) $(LINKFLAGS) $(LDFLAGS) $^ $(LIBS) -o $@


help:
	@echo "Targets:"
	@echo "    all      -> build the program"
	@echo "    run      -> run the program, using the datafile in the factorio installation (see Configuration below)"
	@echo "                Note: this will NOT install the mod or (re)create the datafile. Do this manually by"
	@echo "                      running 'make datafile' before."
	@echo "    mod      -> install the lua mod into the factorio installation (see Configuration below)"
	@echo "    datafile -> update the lua mod and re-create its output datafile"
	@echo "    clean    -> all generated files (including depend. except config.mk)"
	@echo "    info     -> show an overview of the CFLAGS used"
	@echo "    help     -> show this help"
	@echo
	@echo "Configuration:"
	@echo "    Edit the 'config.mk' file and adjust the factorio path."
	@echo "    This path will be used by the 'run', 'mod' and 'outfile' targets"
	

info:
	@echo DEBUGFLAGS = $(DEBUGFLAGS)
	@echo FASTFLAGS = $(FASTFLAGS)
	@echo DEBUG = $(DEBUG)
	@echo CXXFLAGS_BASE = $(CXXFLAGS_BASE)
	@echo CXXFLAGS = $(CXXFLAGS)
	@echo LDFLAGS= $(LDFLAGS)

run: $(EXE)
	./$(EXE)

mod: $(MODDESTS)

DATAFILE=$(FACTORIODIR)/script-output/output1.txt
SAVEGAME=$(FACTORIODIR)/factorio-bot.zip
SERVERSETTINGS=luamod/server-settings.json

datafile: $(DATAFILE)
	echo 'made target $(DATAFILE)'

rm_datafile:
	rm -f $(DATAFILE)
savegame: $(SAVEGAME)

$(SAVEGAME):
	$(FACTORIODIR)/bin/x64/factorio --create $@

.PRECIOUS: $(DATAFILE)

$(DATAFILE): $(MODDESTS) $(SAVEGAME) $(SERVERSETTINGS)
	rm -f $(DATAFILE)
	cp $(SAVEGAME) $(SAVEGAME:.zip=.tmp.zip)
	( sleep 5; ./rcon-client localhost 1234 trivial_password '/c remote.call("windfisch","whoami","server")'; sleep 1; ./rcon-client localhost 1234 trivial_password '/c remote.call("windfisch","whoami","server")' ) &
	-$(FACTORIODIR)/bin/x64/factorio --start-server $(SAVEGAME:.zip=.tmp.zip) --server-settings $(SERVERSETTINGS) --rcon-port 1234 --rcon-password trivial_password
	echo
	echo made $(DATAFILE)

# Build system

.PRECIOUS: config.mk
config.mk:
	echo 'FACTORIODIR=/path/to/factorio' > $@
	echo 'COMPILER=GCC' >> $@
	echo '# possible values: GCC, clang' >> $@

$(FACTORIODIR)/mods/$(MODNAME)/%: luamod/$(MODNAME)/%
	mkdir -p $(dir $@)
	cp -a $< $@



include depend

depend: $(ALLOBJECTS:.o=.d)
	cat $^ > $@

%.d: %.cpp
	$(CXX) $(CXXFLAGS) -MM -MT $(@:.d=.o) $< -o $@

gui/%.d: gui/%.cpp
	$(CXX) $(CXXFLAGS) -MM -MT $(@:.d=.o) $(GUIFLAGS) $< -o $@

gui/%.o: gui/%.cpp
	$(CXX) $(CXXFLAGS) $(GUIFLAGS) -c $< -o $@

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@


$(EXE): $(COMMONOBJECTS) main.o
	$(LINK) $(LINKFLAGS) $(LDFLAGS) $^ $(LIBS) -o $@
rcon-client: rcon-client.o rcon.o logging.o
	$(LINK) $(LINKFLAGS) $(LDFLAGS) $^ $(LIBS) -o $@

compile_commands.json:
	bash mk_compile_commands_json.bash > $@
