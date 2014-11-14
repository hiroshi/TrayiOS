#import <Foundation/Foundation.h>
@class UIViewController, RACSignal;

@interface TrayModel : NSObject

+ (TrayModel *)sharedModel;
- (BOOL)handleOpenURL:(NSURL *)url;
- (void)addText:(NSString *)text;
- (void)addDeviceToken:(NSString *)deviceToken;

@property (readonly) NSArray *items;
@property (readonly) RACSignal *signal;

@end
