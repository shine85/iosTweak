ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:13.0
THEOS_PLATFORM_DEB_COMPRESSION = xz
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Tweakvsb6
Tweakvsb6_FILES = Tweak.xm
Tweakvsb6_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
