ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:13.0
THEOS_DEVICE_IP = localhost

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = zhongguodianxinquanguotongyiguanfangfuwupingtai
zhongguodianxinquanguotongyiguanfangfuwupingtai_FILES = Tweak.xm
zhongguodianxinquanguotongyiguanfangfuwupingtai_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
