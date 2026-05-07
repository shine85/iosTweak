include $(THEOS)/makefiles/common.mk

TWEAK_NAME = hemajuchang
hemajuchang_FILES = Tweak.xm
hemajuchang_CFLAGS = -fobjc-arc
HMJDAdBlock_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries
hemajuchang_FRAMEWORKS = UIKit Foundation
INSTALL_TARGET_PROCESS = 河马剧场

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 '河马剧场' || true"
