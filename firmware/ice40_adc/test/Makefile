SUBDIRS := delay pipeline adder lutfir nco multiplier cic spi

.PHONY: $(SUBDIRS)

all: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@