DEBUG = 0
FINALPACKAGE = 1
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.5

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Tweak

# 源代码文件
Tweak_FILES = Tweak.xm
Tweak_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
