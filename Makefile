ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:13.0
THEOS_PACKAGE_DIR ?= packages
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = zhongguoyidongshoujiyingyeting
zhongguoyidongshoujiyingyeting_FILES = Tweak.xm
zhongguoyidongshoujiyingyeting_FRAMEWORKS = UIKit Foundation
include $(THEOS_MAKE_PATH)/tweak.mk
