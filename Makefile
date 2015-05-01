SOURCES_udf = $(wildcard udf_*.c)

OBJECTS_udf = $(SOURCES_udf:.c=.o)

DEF_SQL = drop_funcs.sql create_funcs.sql

MODULE_udf = libmysql_bit_strings_udf.so

define EXTOPTS
ARCH := $(shell uname -m | sed -e s/i.86/i386/)
endef

$(eval $(call EXTOPTS))

ifeq ($(ARCH),i386)
CARCHFLAGS = -march=i486 -fno-strength-reduce
endif

ifeq ($(ARCH),x86_64)
CARCHFLAGS = -march=nocona -fPIC -fprefetch-loop-arrays \
			-maccumulate-outgoing-args -minline-all-stringops \
			-mno-align-stringops -fno-omit-frame-pointer
endif

CC = gcc
OPT = 2
DEBUG =  -g
CFLAGS = -O$(OPT) -I. -W -Wall -D_GNU_SOURCE=1 \
		-Werror -Wundef -MMD -MF deps/$(subst /,%,$(@)).d \
		-I/usr/include/mysql -Ilib\
		$(DEBUG) $(CARCHFLAGS) 

all: $(MODULE_udf) $(DEF_SQL)

$(OBJECTS_udf): %.o: %.c
	test -d deps || mkdir deps
	$(CC) -c $(CFLAGS) -o $(@) $(<)

$(MODULE_udf): $(OBJECTS_udf)
	$(CC) -shared -o $(@) $(^) 

create_funcs.sql: $(SOURCES_udf)
	echo "set sql_log_bin = 0;" > $(@)
	awk '/^\/\/[ \t]*MYSQL_UDF:/ { print "create", $$5, "function", $$3, "returns", $$4, "soname '\''$(MODULE_udf)'\'';"; }' $(^) >> $(@)

drop_funcs.sql: $(SOURCES_udf)
	echo "set sql_log_bin = 0;" > $(@)
	awk '/^\/\/[ \t]*MYSQL_UDF:/ { print "drop function if exists", $$3, ";"; }' $(^) >> $(@)

clean:
	rm -f $(OBJECTS_udf) $(MODULE_udf) $(DEF_SQL)
	rm -rf deps


install:

.PHONY: all clean install

