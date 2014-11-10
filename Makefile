include theos/makefiles/common.mk

TWEAK_NAME = LockGlyph
LockGlyph_FILES = Tweak.xm
LockGlyph_FRAMEWORKS = UIKit CoreGraphics AudioToolbox AVFoundation CoreMedia

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 backboardd"
SUBPROJECTS += lockglyphprefs
include $(THEOS_MAKE_PATH)/aggregate.mk
