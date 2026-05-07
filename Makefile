THEOS_DEVICE_IP = localhost
ARCHS = arm64
TARGET = iphone:latest:13.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Tweakvpol

Tweakvpol_FILES = Tweak.xm
Tweakvpol_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 HippoTheatre"
