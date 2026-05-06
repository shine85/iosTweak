include $(THEOS)/makefiles/common.mk

TWEAK_NAME = hemajuchang
HMJCNoAd_FILES = Tweak.xm
HMJCNoAd_CFLAGS = -fobjc-arc
HMJCNoAd_LDFLAGS = -framework UIKit -framework Foundation

INSTALL_TARGET_PROCESS = 河马剧场   # 或实际进程名 / bundle ID 对应进程

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install_name_tool -change /usr/lib/libsubstrate.dylib /usr/lib/libhooker.dylib $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/HMJCNoAd.dylib || true
