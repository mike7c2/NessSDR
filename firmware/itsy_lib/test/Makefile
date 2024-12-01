SUBDIRS := delay pipeline adder lutfir nco multiplier cic spi hspi
SRC_DIR := ../../src
.PHONY: $(SUBDIRS)

all: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@ SRC_DIR=$(SRC_DIR)