# Silence make
MAKE:=$(MAKE) -s --no-print-directory

# this is the name of our application/project
APP?=hello_world

# These are overriden in board level makefile
ARCH?=arm
ARCH_VER?=armv7-m
CPU?=cortex-m4
MCU?=max32655

# define our board for this project
BOARD?=max32655fthr

#include our board makefile fragment
include board/$(BOARD)/board.mk

# after including the board makefile fragment, 
# it is now safe to use the ARCH variables.
include $(ARCH)/$(ARCH_VER)/arch.mk
include $(ARCH)/$(CPU)/cpu.mk

FIRMWARE:=adi-fw

TARGET_ELF:=$(FIRMWARE).elf
TARGET_BIN:=$(FIRMWARE).bin
TARGET_HEX:=$(FIRMWARE).hex

# add our baremetal include directory
CFLAGS+=-Iinclude/

# compile with debug information suitable for gdb
CFLAGS+=-ggdb

# compile with debugger friendly optimization level
CFLAGS+=-Og

include app/$(APP)/app.mk
include drivers/drivers.mk
include lib/libs.mk
include build_rules.mk
