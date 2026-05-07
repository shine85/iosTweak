# Makefile for theos project
TARGET = iphone:clang:latest:13.0
ARCHS = arm64 arm64e
THEOS_DEVICE_IP = localhost
THEOS_DEVICE_PORT = 2222

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = hemajuchang
hemajuchang_FILES = Tweak.xm
hemajuchang_FRAMEWORKS = UIKit Foundation

# 确保在目标进程启动时加载
INSTALL_TARGET_PROCESS = RiverHorseApp

include $(THEOS_MAKE_PATH)/tweak.mk
