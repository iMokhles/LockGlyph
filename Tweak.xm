#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>
#import "PKGlyphView.h"
#import "SBLockScreenManager.h"

UIView *lockView = nil;
PKGlyphView *fingerglyph = nil;
SystemSoundID unlockSound;

BOOL fingerAlreadyFailed;
BOOL usingGlyph;

BOOL enabled;
BOOL useUnlockSound;
BOOL useTickAnimation;

static void loadPreferences() {
    CFPreferencesAppSynchronize(CFSTR("com.evilgoldfish.lockglyph"));
    enabled = !CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.evilgoldfish.lockglyph")) ? YES : [(id)CFPreferencesCopyAppValue(CFSTR("enabled"), CFSTR("com.evilgoldfish.lockglyph")) boolValue];
 	useUnlockSound = !CFPreferencesCopyAppValue(CFSTR("useUnlockSound"), CFSTR("com.evilgoldfish.lockglyph")) ? YES : [(id)CFPreferencesCopyAppValue(CFSTR("useUnlockSound"), CFSTR("com.evilgoldfish.lockglyph")) boolValue];
 	useTickAnimation = !CFPreferencesCopyAppValue(CFSTR("useTickAnimation"), CFSTR("com.evilgoldfish.lockglyph")) ? YES : [(id)CFPreferencesCopyAppValue(CFSTR("useTickAnimation"), CFSTR("com.evilgoldfish.lockglyph")) boolValue];
}

%hook SBLockScreenScrollView

-(void)didMoveToWindow {
	%orig;
	if (enabled) {
		lockView = (UIView *)self;
		usingGlyph = YES;
		fingerglyph = [[%c(PKGlyphView) alloc] initWithStyle:1];
		fingerglyph.delegate = (id<PKGlyphViewDelegate>)self;
		//fingerglyph.secondaryColor = [UIColor redColor];
		//fingerglyph.primaryColor = [UIColor whiteColor];
		CGRect screen = [[UIScreen mainScreen] bounds];
		fingerglyph.center = CGPointMake(screen.size.width+CGRectGetMidX(screen),screen.size.height-80);
		[self addSubview:fingerglyph];
	}
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
			delayInSeconds = 0.2;
		}
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){ 
			//AudioServicesDisposeSystemSoundID(unlockSound);
		fingerglyph.delegate = nil;
		fingerAlreadyFailed = NO;
		usingGlyph = NO;
		lockView = nil;
		[fingerglyph removeFromSuperview];
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
		[lockView performSelectorOnMainThread:@selector(performFingerScanAnimation) withObject:nil waitUntilDone:YES];
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