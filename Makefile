ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:14.0
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = zhongguoyidongshoujiyingyeting

zhongguoyidongshoujiyingyeting_FILES = Tweak.xm
zhongguoyidongshoujiyingyeting_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
