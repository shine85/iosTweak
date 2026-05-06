DEBUG = 0
FINALPACKAGE = 1
# 支持 rootless 和 roothide 所需的架构
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MyTweak

# 源代码文件
MyTweak_FILES = Tweak.xm
MyTweak_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
