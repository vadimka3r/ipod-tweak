TARGET := iphone:clang:12.4:6.0
ARCHS = armv7
INSTALL_TARGET_PROCESSES = ipodik
include $(THEOS)/makefiles/common.mk
APPLICATION_NAME = ipodik
ipodik_FILES = main.m XXAppDelegate.m XXCalculatorViewController.m XXBrowserViewController.m
ipodik_FRAMEWORKS = UIKit CoreGraphics
ipodik_CFLAGS = -fobjc-arc
include $(THEOS_MAKE_PATH)/application.mk
