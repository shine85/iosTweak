# Makefile
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = hemajuchang
hemajuchang_FILES = Tweak.xm
hemajuchang_FRAMEWORKS = UIKit Foundation

# 指定目标进程的 bundle identifier
INSTALL_TARGET_PROCESS = com.chinamobile.app

include $(THEOS_MAKE_PATH)/tweak.mk
