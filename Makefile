CC = riscv64-unknown-elf-gcc
AR = riscv64-unknown-elf-ar
LIB = libxuartns550.a

default: lib

ARCH ?= rv64imafd
ABI ?= lp64d
CFLAGS += -march=$(ARCH) -mabi=$(ABI)

INCLUDE=common uartns550
CFLAGS += $(INCLUDE:%=-I%)

OPT ?= -O3
CFLAGS += $(OPT)

BUILD_DIR ?= build/$(ARCH)/$(ABI)
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

COMMON_SRC := $(wildcard common/*.c)
COMMON_OBJ := $(COMMON_SRC:common/%.c=$(BUILD_DIR)/%.o)
$(COMMON_OBJ): $(BUILD_DIR)/%.o: common/%.c $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

UART_SRC := $(wildcard uartns550/*.c)
UART_OBJ := $(UART_SRC:uartns550/%.c=$(BUILD_DIR)/%.o)
$(UART_OBJ): $(BUILD_DIR)/%.o: uartns550/%.c $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

OBJ := $(COMMON_OBJ) $(UART_OBJ)
CFLAGS += -nostartfiles \
          -ffunction-sections \
		  -fno-builtin-printf
ifneq ($(findstring rv64,$(ARCH)),)
ARFLAGS=--target=elf64-littleriscv
else
ARFLAGS=--target=elf32-littleriscv
endif
lib: $(BUILD_DIR)/$(LIB)
$(BUILD_DIR)/$(LIB): $(OBJ)
	$(AR) rcs $(ARFLAGS) $@ $^

INSTALL_LIBDIR ?= $(ISP_PREFIX)/local/lib/$(ARCH)/$(ABI)
INSTALL_HEADERS=uartns550/xuartns550.h
INSTALL_HDIR ?= $(ISP_PREFIX)/local/include
install: $(BUILD_DIR)/$(LIB)
	mkdir -p $(INSTALL_LIBDIR)
	cp $^ $(INSTALL_LIBDIR)
	mkdir -p $(INSTALL_HDIR)
	cp $(INSTALL_HEADERS) $(INSTALL_HDIR)

clean:
	rm -rf build