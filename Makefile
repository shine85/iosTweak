include $(THEOS)/makefiles/common.mk

TWEAK_NAME = zhongguodianxinquanguotongyiguanfangfuwupingtai
zhongguodianxinquanguotongyiguanfangfuwupingtai_FILES = Tweak.xm
zhongguodianxinquanguotongyiguanfangfuwupingtai_CFLAGS = -fobjc-arc
zhongguodianxinquanguotongyiguanfangfuwupingtai_LDFLAGS += -framework UIKit -framework Foundation

ARCHS = arm64 arm64e
TARGET = iphone:14.5:13.0

include $(THEOS_MAKE_PATH)/tweak.mk
