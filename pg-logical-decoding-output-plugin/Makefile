# Global makefile for pg_plugins

PG_CONFIG = pg_config
PGXS := $(shell $(PG_CONFIG) --pgxs)
include $(PGXS)

SUBDIRS = decoder_raw

$(recurse)
$(recurse_always)
