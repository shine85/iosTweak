# Makefile
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = zhongguoyidong
zhongguoyidong_FILES = Tweak.xm
zhongguoyidong_FRAMEWORKS = UIKit Foundation

# 指定目标进程的 bundle identifier
INSTALL_TARGET_PROCESS = com.chinamobile.app

include $(THEOS_MAKE_PATH)/tweak.mk
