ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:13.0
THEOS_PACKAGE_DIR_NAME = debs
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = zhongguodianxinquanguotongyiguanfangfuwupingtai
zhongguodianxinquanguotongyiguanfangfuwupingtai_FILES = Tweak.xm
zhongguodianxinquanguotongyiguanfangfuwupingtai_FRAMEWORKS = UIKit Foundation
zhongguodianxinquanguotongyiguanfangfuwupingtai_LIBRARIES = substrate

include $(THEOS_MAKE_PATH)/tweak.mk
