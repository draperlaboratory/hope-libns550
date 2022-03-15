CC = riscv64-unknown-elf-gcc
AR = riscv64-unknown-elf-ar
LIB = libxuartns550.a

default: lib

ARCH ?= rv64imafd
ABI ?= lp64d
CFLAGS += -march=$(ARCH) -mabi=$(ABI)

INCLUDE=common uartns550
CFLAGS += $(INCLUDE:%=-I%)

ifdef DEBUG
OPT ?= -O0
else
OPT ?= -Os
endif
CFLAGS += $(OPT)

BUILD_DIR ?= build/$(ARCH)/$(ABI)
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

COMMON_SRC=common/xil_io.c
ifdef DEBUG
COMMON_SRC += common/xbasic_types.c common/xil_assert.c
endif
COMMON_OBJ=$(COMMON_SRC:common/%.c=$(BUILD_DIR)/%.o)
$(COMMON_OBJ): $(BUILD_DIR)/%.o: common/%.c $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

UART_SRC=uartns550/xuartns550_format.c uartns550/xuartns550_l.c uartns550/xuartns550_options.c uartns550/xuartns550.c
ifdef DEBUG
UART_SRC += uartns550/xuartns550_selftest.c uartns550/xuartns550_stats.c
endif
UART_OBJ=$(UART_SRC:uartns550/%.c=$(BUILD_DIR)/%.o)
$(UART_OBJ): $(BUILD_DIR)/%.o: uartns550/%.c $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

OBJ=$(COMMON_OBJ) $(UART_OBJ)
CFLAGS += -nostartfiles \
          -fdata-sections \
          -ffunction-sections \
		  -fno-builtin-printf \
		  -mcmodel=medany
ifdef DEBUG
CFLAGS += -g -DDEBUG
endif
ifneq ($(findstring rv64,$(ARCH)),)
ARFLAGS=--target=elf64-littleriscv
else
ARFLAGS=--target=elf32-littleriscv
endif
lib: $(BUILD_DIR)/$(LIB)
$(BUILD_DIR)/$(LIB): $(OBJ)
	$(AR) rcs $(ARFLAGS) $@ $^

INSTALL_LIBDIR ?= $(ISP_PREFIX)/local/lib/$(ARCH)/$(ABI)
INSTALL_HEADERS=common/xil_types.h common/xil_io.h common/xbasic_types.h common/xstatus.h uartns550/xuartns550_l.h uartns550/xuartns550.h common/xil_assert.h
INSTALL_HDIR ?= $(ISP_PREFIX)/local/include
install: $(BUILD_DIR)/$(LIB)
	mkdir -p $(INSTALL_LIBDIR)
	cp $^ $(INSTALL_LIBDIR)
	mkdir -p $(INSTALL_HDIR)
	cp $(INSTALL_HEADERS) $(INSTALL_HDIR)

clean:
	rm -rf build