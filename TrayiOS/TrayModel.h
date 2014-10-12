#import <Foundation/Foundation.h>
@class UIViewController, RACSignal;

@interface TrayModel : NSObject

+ (TrayModel *)sharedModel;
- (void)setupDropbox;
- (void)loginFromViewController:(UIViewController *)viewController;
- (BOOL)handleOpenURL:(NSURL *)url;

- (void)addText:(NSString *)text;

@property (readonly) NSArray *items;
@property (readonly) RACSignal *signal;

@end
