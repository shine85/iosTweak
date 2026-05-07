# Makefile for Theos project
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = hemajuchang
hemajuchang_FILES = Tweak.xm
hemajuchang_FRAMEWORKS = UIKit Foundation

# 目标进程的 bundle identifier（河马剧场）
INSTALL_TARGET_PROCESS = com.cbn.hmjc

include $(THEOS_MAKE_PATH)/tweak.mk
