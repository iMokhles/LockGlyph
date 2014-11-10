include theos/makefiles/common.mk
$(shell install_name_tool -id /usr/lib/libcolorpicker_LockGlyph.dylib lib/libcolorpicker.dylib)

BUNDLE_NAME = LockGlyphPrefs
LockGlyphPrefs_FILES = LockGlyphPrefs.mm
LockGlyphPrefs_INSTALL_PATH = /Library/PreferenceBundles
LockGlyphPrefs_FRAMEWORKS = UIKit CoreGraphics QuartzCore
LockGlyphPrefs_PRIVATE_FRAMEWORKS = Preferences
LockGlyphPrefs_LDFLAGS = -Llib -lcolorpicker

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/LockGlyphPrefs.plist$(ECHO_END)
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/usr/lib/$(ECHO_END)
	$(ECHO_NOTHING)cp lib/libcolorpicker.dylib $(THEOS_STAGING_DIR)/usr/lib/libcolorpicker_LockGlyph.dylib$(ECHO_END)
