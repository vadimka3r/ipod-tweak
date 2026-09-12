# Сборка мини-JVM для локальной разработки/теста (хост x86_64/Linux).
# native_console.c даёт "консольную" реализацию UI.*-методов (см.
# native_host.h) — на реальном айподе вместо неё линкуется
# testos/native-bridge/native_uikit.mm внутри Theos-сборки swipeuplock.

CC ?= gcc
CFLAGS ?= -std=c99 -Wall -Wextra -g -O0

SRCS = classfile.c interp.c native_console.c main.c
OBJS = $(SRCS:.c=.o)
BIN = testos-vm

.PHONY: all clean test

all: $(BIN)

$(BIN): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $(OBJS)

%.o: %.c classfile.h interp.h native_host.h
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJS) $(BIN)
