#import <Foundation/Foundation.h>
@class UIViewController;

@interface TrayModel : NSObject

+ (void)setupDropbox;
+ (void)loginFromViewController:(UIViewController *)viewController;
+ (BOOL)handleOpenURL:(NSURL *)url;

+ (void)addText:(NSString *)text;

@end
