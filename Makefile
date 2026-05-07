# Makefile
TARGET := iphone:clang:latest:15.0
INSTALL_TARGET_PROCESS = 花小猪
ARCHS = arm64

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = huaxiaozhu
huaxiaozhu_FILES = Tweak.xm
huaxiaozhu_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
