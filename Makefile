ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:7.0
THEOS_DEVICE_IP = localhost
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = zhongguodianxinquanguotongyiguanfangfuwupingtai
zhongguodianxinquanguotongyiguanfangfuwupingtai_FILES = Tweak.xm
zhongguodianxinquanguotongyiguanfangfuwupingtai_CFLAGS = -fobjc-arc
zhongguodianxinquanguotongyiguanfangfuwupingtai_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/tweak.mk
