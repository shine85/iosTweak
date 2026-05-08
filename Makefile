TARGET = iphone:clang:latest:13.0
ARCHS = arm64 arm64e
THEOS_DEVICE_IP = localhost
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = zhongguoyidongshoujiyingyeting
zhongguoyidongshoujiyingyeting_FILES = Tweak.xm
zhongguoyidongshoujiyingyeting_FRAMEWORKS = UIKit Foundation
zhongguoyidongshoujiyingyeting_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
