# Makefile
# 用于编译本 Tweak，适配 Theos 环境

TARGET = iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = zhongguoyidong
zhongguoyidong_FILES = Tweak.xm
zhongguoyidong_FRAMEWORKS = UIKit Foundation
NoAdCMCC_PRIVATE_FRAMEWORKS = AdSupport

include $(THEOS_MAKE_PATH)/tweak.mk

# 指定要注入的进程（填写目标 App 的 Bundle ID）
INSTALL_TARGET_PROCESS = com.chinamobile.app
