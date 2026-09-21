ARCHS = arm64
TARGET = iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = IBABlackFLEXLoader

IBABlackFLEXLoader_FILES = Tweak.xm
IBABlackFLEXLoader_CFLAGS = -fobjc-arc
IBABlackFLEXLoader_FRAMEWORKS = Foundation UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
