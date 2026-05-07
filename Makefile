DEBUG = 0
FINALPACKAGE = 1
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.5

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = huaxiaozhu

# 源代码文件
huaxiaozhu_FILES = Tweak.xm
huaxiaozhu_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
