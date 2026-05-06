DEBUG = 0
FINALPACKAGE = 1
# 支持 rootless 和 roothide 所需的架构
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = 河马剧场

# 源代码文件
河马剧场_FILES = Tweak.xm
河马剧场_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
