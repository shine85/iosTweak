# Makefile
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
INSTALL_TARGET_PROCESS = ChinaMobile

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = zhongguoyidong
zhongguoyidong_FILES = Tweak.xm
zhongguoyidong_CFLAGS = -fobjc-arc
zhongguoyidong_FRAMEWORKS = UIKit Foundation

include $(THEOS)/makefiles/tweak.mk
