
TARGET := iphone:clang:latest:13.0
ARCHS := arm64
DEBUG := 0
FINALPACKAGE := 1

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = MWDebugMonitor

MWDebugMonitor_FILES = MWDebugMonitor.xm
MWDebugMonitor_CFLAGS = -fobjc-arc
MWDebugMonitor_FRAMEWORKS = UIKit Foundation

include $(THEOS_MAKE_PATH)/library.mk
