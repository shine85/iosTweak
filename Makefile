ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:13.0
THEOS_DEVICE_IP = localhost
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ImportedTweak

ImportedTweak_FILES = Tweak.xm
ImportedTweak_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
