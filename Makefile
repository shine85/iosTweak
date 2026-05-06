include $(THEOS)/makefiles/common.mk

TWEAK_NAME = hemajuchang
HMAdBlock_FILES = Tweak.xm
HMAdBlock_CFLAGS = -fobjc-arc
HMAdBlock_FRAMEWORKS = UIKit Foundation
HMAdBlock_PRIVATE_FRAMEWORKS = AppSupport

# 针对特定进程注入
INSTALL_TARGET_PROCESS = 河马剧场  # 或实际进程名 / Bundle ID

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	@install_name_tool -change /usr/lib/libsubstrate.dylib /Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/HMAdBlock.dylib || true
