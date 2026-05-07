# Makefile
ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
THEOS_DEVICE_IP = localhost
INSTALL_TARGET_PROCESS = com.huaxiaozhu.app   # 花小猪 主包标识
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = huaxiaozhu

$(TWEAK_NAME)_FILES = Tweak.xm
$(TWEAK_NAME)_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
after-install::
	install.exec "killall -9 $(INSTALL_TARGET_PROCESS) && echo '已重启应用，去广告已生效'"
