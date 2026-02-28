LIB_SRCS+=fwtest.c

SRCS+=$(patsubst %.c, lib/%.c, $(LIB_SRCS))
