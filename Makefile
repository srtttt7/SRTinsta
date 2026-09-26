TARGET := iphone:clang:latest:14.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = InstaSRT
InstaSRT_FILES = Tweak.x
InstaSRT_CFLAGS = -fobjc-arc
InstaSRT_FRAMEWORKS = UIKit

include $(THEOS_MAKEPATH)/tweak.mk
