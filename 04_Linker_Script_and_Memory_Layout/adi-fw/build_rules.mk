TOOLCHAIN_PREFIX:=arm-none-eabi

CC:=$(TOOLCHAIN_PREFIX)-gcc
AS:=$(TOOLCHAIN_PREFIX)-as
AR:=$(TOOLCHAIN_PREFIX)-ar
LD:=$(TOOLCHAIN_PREFIX)-ld
NM:=$(TOOLCHAIN_PREFIX)-nm
OBJDUMP:=$(TOOLCHAIN_PREFIX)-objdump
OBJCOPY:=$(TOOLCHAIN_PREFIX)-objcopy

# we substitute the .c extension of all sources files to .o to make them
# valid recipe targets. e.g. we derive a ".o" from a ".c"
OBJS+=$(SRCS:.c=.o)

LINKERSCRIPT?=board/$(BOARD)/linkerscript.ld

all: $(TARGET_ELF)
	@echo "Done building."

$(TARGET_ELF): $(OBJS)
	@echo "LD $@"
	@touch $(TARGET_ELF)

%.o: %.c
	@echo "CC $@"
	@$(CC) $(CFLAGS) -MMD -MP -c -o $@ $<

.PHONY: clean
clean:
	@echo "removing $(TARGET_ELF)..."
	@rm -rf $(TARGET_ELF)
	@echo "removing all object files..."
	@rm -rf $(SRCS:.c=.o)
	@echo "removing all deps..."
	@rm -rf $(SRCS:.c=.d)
	@echo "done."

-include $(SRCS:.c=.d)
