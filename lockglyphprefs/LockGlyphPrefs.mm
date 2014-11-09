#import <Preferences/Preferences.h>

@protocol PreferencesTableCustomView
- (id)initWithSpecifier:(id)arg1;

@optional
- (CGFloat)preferredHeightForWidth:(CGFloat)arg1;
- (CGFloat)preferredHeightForWidth:(CGFloat)arg1 inTableView:(id)arg2;
@end

@interface PSTableCell ()
- (id)initWithStyle:(int)style reuseIdentifier:(id)arg2;
@end

@interface LockGlyphPrefsListController: PSListController {
}
@end

@implementation LockGlyphPrefsListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"LockGlyphPrefs" target:self] retain];
	}
	return _specifiers;
}

-(void)twitterButton {
    NSString *user = @"evilgoldfish01";
    if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot:"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tweetbot:///user_profile/" stringByAppendingString:user]]];
    
    else if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific:"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"twitterrific:///profile?screen_name=" stringByAppendingString:user]]];
    
    else if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetings:"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"tweetings:///user?screen_name=" stringByAppendingString:user]]];
    
    else if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"twitter://user?screen_name=" stringByAppendingString:user]]];
    
    else
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[@"https://mobile.twitter.com/" stringByAppendingString:user]]];

}
@end

@interface LockGlyphTitleCell : PSTableCell <PreferencesTableCustomView> {
    UILabel *tweakTitle;
    UILabel *tweakSubtitle;
}

@end

@implementation LockGlyphTitleCell

- (id)initWithSpecifier:(PSSpecifier *)specifier
{
    self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    
    if (self) {
        
        int width = [[UIScreen mainScreen] bounds].size.width;
        
        CGRect frame = CGRectMake(0, -30, width, 60);
        CGRect subtitleFrame = CGRectMake(0, 5, width, 60);
        
        tweakTitle = [[UILabel alloc] initWithFrame:frame];
        [tweakTitle setNumberOfLines:1];
        [tweakTitle setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:48]];
        [tweakTitle setText:@"LockGlyph"];
        [tweakTitle setBackgroundColor:[UIColor clearColor]];
        [tweakTitle setTextColor:[UIColor blackColor]];
        [tweakTitle setTextAlignment:NSTextAlignmentCenter];
        
        tweakSubtitle = [[UILabel alloc] initWithFrame:subtitleFrame];
        [tweakSubtitle setNumberOfLines:1];
        [tweakSubtitle setFont:[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:20]];
        [tweakSubtitle setText:@"By evilgoldfish."];
        [tweakSubtitle setBackgroundColor:[UIColor clearColor]];
        [tweakSubtitle setTextColor:[UIColor blackColor]];
        [tweakSubtitle setTextAlignment:NSTextAlignmentCenter];
        
        [self addSubview:tweakTitle];
        [self addSubview:tweakSubtitle];
    }
    
    return self;
}

@end

// vim:ft=objc
