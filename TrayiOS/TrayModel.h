#import <Foundation/Foundation.h>
@class UIViewController, RACSignal;

@interface TrayModel : NSObject

+ (TrayModel *)sharedModel;
- (BOOL)handleOpenURL:(NSURL *)url;
// Items
- (void)addText:(NSString *)text;
- (void)removeItemAtIndex:(NSInteger)index;
- (NSArray *)items;
// DeviceTokens
- (void)addDeviceToken:(NSString *)deviceToken;

@property (readonly) RACSignal *signal;

@end
