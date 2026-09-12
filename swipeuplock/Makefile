TARGET := iphone:clang:12.4:6.0
ARCHS = armv7
INSTALL_TARGET_PROCESSES = SpringBoard
include $(THEOS)/makefiles/common.mk
TWEAK_NAME = swipeuplock
swipeuplock_FILES = Tweak.xm
swipeuplock_CFLAGS = -fobjc-arc
include $(THEOS_MAKE_PATH)/tweak.mk
