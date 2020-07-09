SOURCES=$(wildcard local/*)
DESTS=$(patsubst local/%,www/%,$(SOURCES))

.phony: all

all: $(DESTS)

www/%: local/%
	cp $< $@

