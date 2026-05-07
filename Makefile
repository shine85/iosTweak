TARGET = iphone:clang:latest:14.0
INSTALL_TARGET_PROCESS = 河马剧场
ARCHS = arm64
THEOS_DEVICE_IP = 192.168.1.100  # 替换为实际测试设备 IP
THEOS_DEVICE_PORT = 22

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = hemajuchang
hemajuchang_FILES = Tweak.xm
hemajuchang_CFLAGS = -fobjc-arc -fvisibility=hidden
hemajuchang_LDFLAGS += -lobjc -ldl

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 河马剧场"
