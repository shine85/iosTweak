include $(THEOS)/makefiles/common.mk

TWEAK_NAME = hemajuchang
hemajuchang_FILES = Tweak.xm
hemajuchang_CFLAGS = -fobjc-arc
HMJAdBlock_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries
HMJAdBlock_LOGOS_DEFAULT_GENERATOR = MobileSubstrate

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install_name_tool -change /Library/Frameworks/CydiaSubstrate.framework/CydiaSubstrate /usr/lib/libsubstrate.dylib $(THEOS_STAGING_DIR)/Library/MobileSubstrate/DynamicLibraries/HMJAdBlock.dylib
