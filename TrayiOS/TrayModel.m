#import "TrayModel.h"
#import <Dropbox/Dropbox.h>
#import <ReactiveCocoa.h>
#import "Secrets.h"

@interface TrayModel ()

@property (nonatomic, strong) DBDatastore *defaultDatastore;
@property (nonatomic, strong) RACSubject *subject;
@property (nonatomic, assign) BOOL linking;

@end


@implementation TrayModel

+ (TrayModel *)sharedModel
{
    static TrayModel *model;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        model = [TrayModel new];
    });
    return model;
}

- (id)init
{
    self = [super init];
    if (!self) {
        return nil;
    }
    self.subject = [RACReplaySubject replaySubjectWithCapacity:1];
    return self;
}

- (BOOL)handleOpenURL:(NSURL *)url
{
    DBAccount *account = [[DBAccountManager sharedManager] handleOpenURL:url];
    if (account) {
        NSLog(@"App linked successfully!");
        // Migrate any local datastores to the linked account
        DBDatastoreManager *localManager = [DBDatastoreManager localManagerForAccountManager:[DBAccountManager sharedManager]];
        [localManager migrateToAccount:account error:nil];
        // Now use Dropbox datastores
        [DBDatastoreManager setSharedManager:[DBDatastoreManager managerForAccount:account]];
        return YES;
    }
    return NO;
}

- (DBAccountManager *)sharedAccountManager
{
    if (![DBAccountManager sharedManager]) {
        DBAccountManager *accountManager = [[DBAccountManager alloc] initWithAppKey:DROPBOX_APP_KEY secret:DROPBOX_APP_SECRET];
        [DBAccountManager setSharedManager:accountManager];
    }
    return [DBAccountManager sharedManager];
}

- (DBDatastoreManager *)sharedDatastoreManager
{
    if (![DBDatastoreManager sharedManager]) {
        if ([self sharedAccountManager]) {
            // Set up the datastore manager
            DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
            if (account) {
                // Use Dropbox datastores
                [DBDatastoreManager setSharedManager:[DBDatastoreManager managerForAccount:account]];
            } else if (!self.linking) {
                self.linking = YES;
                UIViewController *viewController = ((UIWindow *)[UIApplication sharedApplication].windows[0]).rootViewController;
                if ([viewController isKindOfClass:[UINavigationController class]]) {
                    viewController = ((UINavigationController *)viewController).visibleViewController;
                }
                [[DBAccountManager sharedManager] linkFromController:viewController];
            }
        }
    }
    return [DBDatastoreManager sharedManager];
}

- (void)addText:(NSString *)text
{
    DBTable *itemsTable = [self.defaultDatastore getTable:@"items"];
    NSDate *now = [NSDate date];
    /*DBRecord *itemRecord =*/ [itemsTable insert:@{ @"text": text, @"createDate": now, @"orderDate": now}];
    [self.defaultDatastore sync:nil];
    NSLog(@"AddText: %@", text);
    [self.subject sendNext:nil];
    //self.signal sendNex
}

- (NSArray *)items
{
    DBError *error = nil;
    DBTable *itemsTable = [self.defaultDatastore getTable:@"items"];
    NSArray *records = [itemsTable query:nil error:&error];
    if (error) {
        NSLog(@"query items failed: %@", error);
    }
    return [[records.rac_sequence map:^id(DBRecord *record) {
        return record.fields;
    }].array sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"orderDate" ascending:NO]]];
}

- (RACSignal *)signal
{
    return self.subject;
}


#pragma mark - private

- (DBDatastore *)defaultDatastore
{
    if (!_defaultDatastore) {
        DBError *error = nil;
        self.defaultDatastore = [[self sharedDatastoreManager] openDefaultDatastore:&error];
        if (error) {
            NSLog(@"openDefaultDatastore failed: %@", error);
        }
    }
    return _defaultDatastore;
}

@end
