# Сборка мини-JVM для локальной разработки/теста (хост x86_64/Linux).
# Кросс-компиляция под armv7-apple-darwin (iOS) добавится в M3 отдельным
# таргетом через тот же Theos-тулчейн, что и swipeuplock.

CC ?= gcc
CFLAGS ?= -std=c99 -Wall -Wextra -g -O0

SRCS = classfile.c interp.c main.c
OBJS = $(SRCS:.c=.o)
BIN = testos-vm

.PHONY: all clean test

all: $(BIN)

$(BIN): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $(OBJS)

%.o: %.c classfile.h interp.h
	$(CC) $(CFLAGS) -c -o $@ $<

clean:
	rm -f $(OBJS) $(BIN)
