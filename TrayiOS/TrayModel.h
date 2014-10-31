#import <Foundation/Foundation.h>
@class UIViewController, RACSignal;

@interface TrayModel : NSObject

+ (TrayModel *)sharedModel;
- (BOOL)handleOpenURL:(NSURL *)url;
- (void)addText:(NSString *)text;
- (void)removeItemAtIndex:(NSInteger)index;
- (void)addDeviceToken:(NSString *)deviceToken;

@property (readonly) NSArray *items;
@property (readonly) RACSignal *signal;

@end
