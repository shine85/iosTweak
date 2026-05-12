DEBUG = 0
FINALPACKAGE = 1
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.5

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = zhongguoyidongshoujiyingyeting

# 源代码文件
zhongguoyidongshoujiyingyeting_FILES = Tweak.xm
zhongguoyidongshoujiyingyeting_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
