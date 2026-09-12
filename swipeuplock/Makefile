TARGET := iphone:clang:12.4:6.0
ARCHS = armv7
INSTALL_TARGET_PROCESSES = SpringBoard
include $(THEOS)/makefiles/common.mk
TWEAK_NAME = swipeuplock
# testos/vm/*.c — переносимое ядро мини-JVM (то же самое, что собирается
# отдельно в testos/vm/Makefile для теста на Linux).
# native-bridge/native_uikit.mm — UIKit-реализация native_host.h для iOS
# (НЕ путать с testos/vm/native_console.c — тот для консоли/Linux,
# линковать оба разом нельзя, будет конфликт символов host_*()).
swipeuplock_FILES = Tweak.xm ../testos/vm/classfile.c ../testos/vm/interp.c ../testos/native-bridge/native_uikit.mm
swipeuplock_CFLAGS = -fobjc-arc -I../testos/vm -I../testos/native-bridge
include $(THEOS_MAKE_PATH)/tweak.mk
