#import "ActionRequestHandler.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <ReactiveCocoa.h>
#import "TrayModel.h"

@interface ActionRequestHandler ()

@end

@implementation ActionRequestHandler

- (void)beginRequestWithExtensionContext:(NSExtensionContext *)context {
    // Do not call super in an Action extension with no user interface
    NSMutableArray *signals = [[NSMutableArray alloc] initWithCapacity:3];
    for (NSExtensionItem *item in context.inputItems) {
        for (NSItemProvider *itemProvider in item.attachments) {
            NSArray *types = @[(NSString *)kUTTypePlainText, (NSString *)kUTTypeURL, (NSString *)kUTTypePropertyList];
            for (NSString *type in types) {
                if ([itemProvider hasItemConformingToTypeIdentifier:type]) {
                    RACReplaySubject *subject = [RACReplaySubject replaySubjectWithCapacity:1];
                    [signals addObject:subject];
                    [itemProvider loadItemForTypeIdentifier:type options:nil completionHandler:^(id <NSSecureCoding> item, NSError *error) {
                        NSLog(@"item: %@", item);
                        [subject sendNext:item];
                        [subject sendCompleted];
                    }];
                }
            }
        }
    }
    [[RACSignal combineLatest:signals] subscribeNext:^(RACTuple *items) {
        //NSLog(@"next: %@", items);
        NSString *title = nil;
        NSString *urlString = nil;
        NSString *append = nil;
        for (id item in items) {
            if ([item isKindOfClass:[NSString class]]) {
                title = (NSString *)item;
            } else if ([item isKindOfClass:[NSURL class]]) {
                urlString = ((NSURL *)item).absoluteString;
            } else if ([item isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dict = ((NSDictionary *)item)[NSExtensionJavaScriptPreprocessingResultsKey];
                title = dict[@"title"];
                urlString = dict[@"url"];
                append = dict[@"selectedText"];
            }
        }
        NSMutableArray *array = [NSMutableArray array];
        if (title) {
            [array addObject:title];
        }
        if (urlString) {
            [array addObject:urlString];
        }
        if (append) {
            if (array.count > 0) {
                [array addObject:@""];
            }
            [array addObject:append];
        }
        [[TrayModel sharedModel] addText:[array componentsJoinedByString:@"\n"]];
    } error:^(NSError *error) {
        NSLog(@"error: %@", error);
    } completed:^{
        NSLog(@"complete");
    }];
}

//- (void)itemLoadCompletedWithPreprocessingResults:(NSDictionary *)javaScriptPreprocessingResults {
//    // Here, do something, potentially asynchronously, with the preprocessing
//    // results.
//    
//    // In this very simple example, the JavaScript will have passed us the
//    // current background color style, if there is one. We will construct a
//    // dictionary to send back with a desired new background color style.
//    if ([javaScriptPreprocessingResults[@"currentBackgroundColor"] length] == 0) {
//        // No specific background color? Request setting the background to red.
//        [self doneWithResults:@{ @"newBackgroundColor": @"red" }];
//    } else {
//        // Specific background color is set? Request replacing it with green.
//        [self doneWithResults:@{ @"newBackgroundColor": @"green" }];
//    }
//}
//
//- (void)doneWithResults:(NSDictionary *)resultsForJavaScriptFinalize {
//    if (resultsForJavaScriptFinalize) {
//        // Construct an NSExtensionItem of the appropriate type to return our
//        // results dictionary in.
//        
//        // These will be used as the arguments to the JavaScript finalize()
//        // method.
//        
//        NSDictionary *resultsDictionary = @{ NSExtensionJavaScriptFinalizeArgumentKey: resultsForJavaScriptFinalize };
//        
//        NSItemProvider *resultsProvider = [[NSItemProvider alloc] initWithItem:resultsDictionary typeIdentifier:(NSString *)kUTTypePropertyList];
//        
//        NSExtensionItem *resultsItem = [[NSExtensionItem alloc] init];
//        resultsItem.attachments = @[resultsProvider];
//        
//        // Signal that we're complete, returning our results.
//        [self.extensionContext completeRequestReturningItems:@[resultsItem] completionHandler:nil];
//    } else {
//        // We still need to signal that we're done even if we have nothing to
//        // pass back.
//        [self.extensionContext completeRequestReturningItems:@[] completionHandler:nil];
//    }
//    
//    // Don't hold on to this after we finished with it.
//    self.extensionContext = nil;
//}

@end
