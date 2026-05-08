TARGET = iphone:clang:latest:13.0
ARCHS = arm64 arm64e
THEOS_DEVICE_IP = 127.0.0.1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = zhongguoyidongshoujiyingyeting

zhongguoyidongshoujiyingyeting_FILES = Tweak.xm
zhongguoyidongshoujiyingyeting_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
