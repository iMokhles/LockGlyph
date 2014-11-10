#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>
#import "PKGlyphView.h"
#import "SBLockScreenManager.h"

#define TouchIDFingerDown  1
#define TouchIDFingerUp    0
#define TouchIDFingerHeld  2
#define TouchIDMatched     3
#define TouchIDNotMatched  10

#define kDefaultPrimaryColor [[UIColor alloc] initWithRed:188/255.0f green:188/255.0f blue:188/255.0f alpha:1.0f]
#define kDefaultSecondaryColor [[UIColor alloc] initWithRed:119/255.0f green:119/255.0f blue:119/255.0f alpha:1.0f]

UIView *lockView = nil;
PKGlyphView *fingerglyph = nil;
SystemSoundID unlockSound;

BOOL fingerAlreadyFailed;
BOOL usingGlyph;

BOOL enabled;
BOOL useUnlockSound;
BOOL useTickAnimation;
UIColor *primaryColor;
UIColor *secondaryColor;

static UIColor* parseColorFromPreferences(NSString* string) {
	NSArray *prefsarray = [string componentsSeparatedByString: @":"];
	NSString *hexString = [prefsarray objectAtIndex:0];
	double alpha = [[prefsarray objectAtIndex:1] doubleValue];

	unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    [scanner setScanLocation:1]; // bypass '#' character
    [scanner scanHexInt:&rgbValue];
    return [[UIColor alloc] initWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:alpha];
}

static void loadPreferences() {
    CFPreferencesAppSynchronize(CFSTR("com.evilgoldfish.lockglyph"));
    enabled = !CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.evilgoldfish.lockglyph")) ? YES : [(id)CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.evilgoldfish.lockglyph")) boolValue];
 	useUnlockSound = !CFPreferencesCopyAppValue(CFSTR("useUnlockSound"), CFSTR("com.evilgoldfish.lockglyph")) ? YES : [(id)CFPreferencesCopyAppValue(CFSTR("useUnlockSound"), CFSTR("com.evilgoldfish.lockglyph")) boolValue];
 	useTickAnimation = !CFPreferencesCopyAppValue(CFSTR("useTickAnimation"), CFSTR("com.evilgoldfish.lockglyph")) ? NO : [(id)CFPreferencesCopyAppValue(CFSTR("useTickAnimation"), CFSTR("com.evilgoldfish.lockglyph")) boolValue];
 	primaryColor = !CFPreferencesCopyAppValue(CFSTR("primaryColor"), CFSTR("com.evilgoldfish.lockglyph")) ? kDefaultPrimaryColor : parseColorFromPreferences((id)CFPreferencesCopyAppValue(CFSTR("primaryColor"), CFSTR("com.evilgoldfish.lockglyph")));
 	secondaryColor = !CFPreferencesCopyAppValue(CFSTR("secondaryColor"), CFSTR("com.evilgoldfish.lockglyph")) ? kDefaultSecondaryColor : parseColorFromPreferences((id)CFPreferencesCopyAppValue(CFSTR("secondaryColor"), CFSTR("com.evilgoldfish.lockglyph")));
}

%hook SBLockScreenScrollView

-(UIView *)initWithFrame:(CGRect)frame {
	lockView = %orig;
	if (enabled) {
		lockView = (UIView *)self;
		usingGlyph = YES;
		fingerglyph = [[%c(PKGlyphView) alloc] initWithStyle:1];
		fingerglyph.delegate = (id<PKGlyphViewDelegate>)self;
		fingerglyph.secondaryColor = secondaryColor;
		fingerglyph.primaryColor = primaryColor;
		CGRect screen = [[UIScreen mainScreen] bounds];
		fingerglyph.center = CGPointMake(screen.size.width+CGRectGetMidX(screen),screen.size.height-60);
		[self addSubview:fingerglyph];
	}
	return lockView;
}

%new(v@:)
-(void)performFingerScanAnimation {
	if (!fingerAlreadyFailed) {
		[fingerglyph setState:1 animated:YES completionHandler:nil];
		fingerAlreadyFailed = YES;
	}
}

%new(v@:)
-(void)performTickAnimation {
	[fingerglyph setState:6 animated:YES completionHandler:nil];
}

%new(v@:@c)
- (void)glyphView:(PKGlyphView *)arg1 revealingCheckmark:(BOOL)arg2 {
	if (useUnlockSound && useTickAnimation) {
		AudioServicesPlaySystemSound(unlockSound);
	}
}

%end

/*%hook PKGlyphView

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	%orig;
	if (usingGlyph && )
	//lel
}

%end*/

%hook SBLockScreenManager

- (void)_bioAuthenticated:(id)arg1 {
	if (lockView && self.isUILocked && enabled) {
		[lockView performSelectorOnMainThread:@selector(performTickAnimation) withObject:nil waitUntilDone:YES];
		double delayInSeconds = 1.3;
		if (!useTickAnimation) {
			delayInSeconds = 0.3;
		}
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){ 
			//AudioServicesDisposeSystemSoundID(unlockSound);
			if (!useTickAnimation && useUnlockSound) {
				AudioServicesPlaySystemSound(unlockSound);
			}
			fingerglyph.delegate = nil;
			fingerAlreadyFailed = NO;
			usingGlyph = NO;
			lockView = nil;
			//[fingerglyph removeFromSuperview];
			fingerglyph = nil;
			%orig; });
	} else {
		%orig;
	}
}

- (void)biometricEventMonitor:(id)arg1 handleBiometricEvent:(unsigned long long)arg2 {
	%orig;
	//start animation
	if (lockView && self.isUILocked && enabled) {
		switch (arg2) {
			case TouchIDFingerDown:
				[lockView performSelectorOnMainThread:@selector(performFingerScanAnimation) withObject:nil waitUntilDone:YES];
				break;
			case TouchIDFingerUp:
				// revert to state 0 here
		}
	}
}

/*- (void)_finishUIUnlockFromSource:(int)arg1 withOptions:(id)arg2 {
	%orig;
	fingerAlreadyFailed = NO;
	usingGlyph = NO;
	lockView = nil;
	[fingerglyph removeFromSuperview];
	fingerglyph = nil;
}*/

%end

%hook SBLockScreenView

- (void)_layoutSlideToUnlockView {
	if (enabled) {
		return;
	}
	%orig;
}

%end

%ctor {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    (CFNotificationCallback)loadPreferences,
                                    CFSTR("com.evilgoldfish.lockglyph.settingschanged"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorCoalesce);
	loadPreferences();
	NSURL *pathURL = [NSURL fileURLWithPath: @"/System/Library/Frameworks/PassKit.framework/Payment_Success.wav"];
	AudioServicesCreateSystemSoundID((__bridge CFURLRef) pathURL, &unlockSound);
	[pool release];
}