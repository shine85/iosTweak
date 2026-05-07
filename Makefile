# Makefile
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = hemajuchang
hemajuchang_FILES = Tweak.xm
hemajuchang_CFLAGS = -fobjc-arc
hemajuchang_FRAMEWORKS = UIKit Foundation

# 针对特定进程注入
INSTALL_TARGET_PROCESS = 河马剧场  # 或 bundle id: com.hema.juchang

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install_name_tool -change /usr/lib/libsubstrate.dylib /usr/lib/libhooker.dylib $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/HemaNoAds.dylib || true
