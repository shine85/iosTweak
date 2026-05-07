# Makefile
TARGET = iphone:clang:latest:14.0
ARCHS = arm64
THEOS_DEVICE_IP = localhost

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = zhongguoyidong

zhongguoyidong_FILES = Tweak.xm
zhongguoyidong_FRAMEWORKS = UIKit Foundation
ChinaMobileAdBlock_PRIVATE_FRAMEWORKS = AdSupport

# 目标进程的 bundle identifier
INSTALL_TARGET_PROCESS = com.chinamobile.app

include $(THEOS_MAKE_PATH)/tweak.mk
