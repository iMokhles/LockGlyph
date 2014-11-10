#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <CoreMedia/CoreMedia.h>
#include <objc/runtime.h>
#import <MediaPlayer/MediaPlayer.h>
#import "PKGlyphView.h"
#import "SBLockScreenManager.h"

@interface NSTimer (block)
+(id)scheduledTimerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)())inBlock repeats:(BOOL)inRepeats;
+(id)timerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)())inBlock repeats:(BOOL)inRepeats;
@end

@implementation NSTimer (block)

+(id)scheduledTimerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)())inBlock repeats:(BOOL)inRepeats {
    void (^block)() = [inBlock copy];
    id ret = [self scheduledTimerWithTimeInterval:inTimeInterval target:self selector:@selector(jdExecuteSimpleBlock:) userInfo:block repeats:inRepeats];
    return ret;
}

+(id)timerWithTimeInterval:(NSTimeInterval)inTimeInterval block:(void (^)())inBlock repeats:(BOOL)inRepeats {
    void (^block)() = [inBlock copy];
    id ret = [self timerWithTimeInterval:inTimeInterval target:self selector:@selector(jdExecuteSimpleBlock:) userInfo:block repeats:inRepeats];
    return ret;
}

+(void)jdExecuteSimpleBlock:(NSTimer *)inTimer;
{
    if([inTimer userInfo])
    {
        void (^block)() = (void (^)())[inTimer userInfo];
        block();
    }
}
@end

@interface SBMediaController : NSObject
+ (void)sendResetPlaybackTimeoutCommand;
+ (void)interrupt;
+ (BOOL)applicationCanBeConsideredNowPlaying:(id)arg1;
+ (id)sharedInstance;
@property(nonatomic, getter=isRingerMuted) BOOL ringerMuted;
- (BOOL)muted;
- (void)setVolume:(float)arg1;
- (float)volume;
- (BOOL)stop;
- (BOOL)togglePlayPause;
- (BOOL)pause;
- (BOOL)play;
- (BOOL)isRadioTrack;
- (BOOL)isAdvertisement;
- (BOOL)isTVOut;
- (BOOL)isMovie;
- (BOOL)isPaused;
- (BOOL)isPlaying;
- (BOOL)isLastTrack;
- (BOOL)isFirstTrack;
@end

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
static AVAudioPlayer* audioPlayer;

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
				break;
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

%new
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:NO error:nil];
    
}
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
	AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:pathURL options:nil];
    CMTime time = asset.duration;
    double durationInSeconds = CMTimeGetSeconds(time);
    if (![(SBMediaController *)[objc_getClass("SBMediaController") sharedInstance] isPlaying] && ![(SBMediaController *)[objc_getClass("SBMediaController") sharedInstance] isRingerMuted]) {
		if (audioPlayer) {
	        [audioPlayer stop];
	        AVAudioSession *session = [AVAudioSession sharedInstance];
	        [session setActive:NO error:nil];
	        audioPlayer = nil;
	    }
	    
	    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:pathURL error:nil];
	    [audioPlayer setDelegate:[[objc_getClass("SBLockScreenManager") alloc] init]];
	    audioPlayer.volume = 0.5; //between 0 and 1
	    AVAudioSession *session = [AVAudioSession sharedInstance];
	    [session setActive:YES error:nil];
	    [audioPlayer play];
    } else if ([(SBMediaController *)[objc_getClass("SBMediaController") sharedInstance] isPlaying]){
    	//
        [(SBMediaController *)[objc_getClass("SBMediaController") sharedInstance] pause];
		if (audioPlayer) {
	        [audioPlayer stop];
	        AVAudioSession *session = [AVAudioSession sharedInstance];
	        [session setActive:NO error:nil];
	        audioPlayer = nil;
	    }
	    
	    audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:pathURL error:nil];
	    [audioPlayer setDelegate:[[objc_getClass("SBLockScreenManager") alloc] init]];
	    audioPlayer.volume = 0.5; //between 0 and 1
	    AVAudioSession *session = [AVAudioSession sharedInstance];
	    [session setActive:YES error:nil];
	    [audioPlayer play];
        [NSTimer scheduledTimerWithTimeInterval:durationInSeconds block:^{
            [(SBMediaController *)[objc_getClass("SBMediaController") sharedInstance] togglePlayPause];
        } repeats:NO];
    } else if ([(SBMediaController *)[objc_getClass("SBMediaController") sharedInstance] isRingerMuted]) {
        AudioServicesCreateSystemSoundID((__bridge CFURLRef) pathURL, &unlockSound);
    }
	// AudioServicesCreateSystemSoundID((__bridge CFURLRef) pathURL, &unlockSound);
	[pool release];
}