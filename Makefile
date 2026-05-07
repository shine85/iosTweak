include $(THEOS)/makefiles/common.mk

TWEAK_NAME = hemajuchang

hemajuchang_FILES = Tweak.xm
hemajuchang_CFLAGS = -fobjc-arc
hemajuchang_LIBRARIES = substrate

INSTALL_TARGET_PROCESS = HippoTheater  # 替换为实际进程名（可通过 ps 或 frida 确认）

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 HippoTheater || true"
