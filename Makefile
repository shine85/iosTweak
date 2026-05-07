include $(THEOS)/makefiles/common.mk

TWEAK_NAME = huaxiaozhu

huaxiaozhu_FILES = Tweak.xm
huaxiaozhu_CFLAGS = -fobjc-arc
huaxiaozhu_FRAMEWORKS = UIKit Foundation

INSTALL_TARGET_PROCESS = HuaXiaoZhu

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install_name_tool -change /usr/lib/libsubstrate.dylib /Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/HuaXiaoZhuNoAd.dylib || true
