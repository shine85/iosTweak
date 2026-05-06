# Makefile for 河马剧场去广告 Tweak

TARGET := iphone:clang:latest:14.0
ARCHS := arm64 arm64e
INSTALL_TARGET_PROCESSES = 河马剧场  # 或实际进程名

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Tweak

HemajuchangNoAd_FILES = Tweak.xm
HemajuchangNoAd_CFLAGS = -fobjc-arc
HemajuchangNoAd_FRAMEWORKS = UIKit Foundation
# 如需额外链接
# HemajuchangNoAd_PRIVATE_FRAMEWORKS = 

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 河马剧场 || true"
