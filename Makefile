TARGET = iphone:clang:latest:13.0
ARCHS = arm64 arm64e
THEOS_PACKAGE_DIR ?= ./packages
INSTALL_TARGET_PROCESSES = cn.10086.app

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = id583700738
id583700738_FILES = Tweak.xm
id583700738_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 cn.10086.app"
