
TARGET := iphone:clang:latest:13.0
ARCHS := arm64

DEBUG := 0
FINALPACKAGE := 1

LIBRARY_NAME = MWDebugMonitor

MWDebugMonitor_FILES = MWDebugMonitor.xm
MWDebugMonitor_CFLAGS = -fobjc-arc
MWDebugMonitor_FRAMEWORKS = UIKit Foundation

# Disable dyld shared-cache eligibility
MWDebugMonitor_LDFLAGS += -Wl,-no_dyld_shared_cache

include $(THEOS)/makefiles/common.mk
include $(THEOS_MAKE_PATH)/library.mk
