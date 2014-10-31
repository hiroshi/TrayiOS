#import "TrayModel.h"
#import <Dropbox/Dropbox.h>
#import <ReactiveCocoa.h>
#import "Secrets.h"

@implementation DBRecord (keyValue)

- (id)valueForUndefinedKey:(NSString *)key
{
    return [self objectForKey:key];
}

@end



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
#if !TARGET_EXTENSION
        // Store url for extensions
        NSUserDefaults *groupDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.yakitara.Tray"];
        [groupDefaults setObject:url.absoluteString forKey:@"dropbox.token.url"];
        [groupDefaults synchronize];
#endif
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
#if TARGET_EXTENSION
                //NSLog(@"No dropbox account link in an extension.");
                // Store url for extensions
                NSUserDefaults *groupDefaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.com.yakitara.Tray"];
                NSURL *url = [NSURL URLWithString:[groupDefaults objectForKey:@"dropbox.token.url"]];
                NSLog(@"dropbox.token.url=%@", url);
                for (NSString *pair in [url.query componentsSeparatedByString:@"&"]) {
                    NSArray *kv = [pair componentsSeparatedByString:@"="];
                    if ([kv[0] isEqual:@"state"]) {
                        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                        [defaults setObject:kv[1] forKey:@"dropbox.sync.nonce"];
                        [defaults synchronize];
                        NSLog(@"store nonce: %@", kv[1]);
                        break;
                    }
                }
                account = [[DBAccountManager sharedManager] handleOpenURL:url];
                [DBDatastoreManager setSharedManager:[DBDatastoreManager managerForAccount:account]];
#else
                UIViewController *viewController = ((UIWindow *)[UIApplication sharedApplication].windows[0]).rootViewController;
                if ([viewController isKindOfClass:[UINavigationController class]]) {
                    viewController = ((UINavigationController *)viewController).visibleViewController;
                }
                [[DBAccountManager sharedManager] linkFromController:viewController];
#endif
            }
        }
    }
    return [DBDatastoreManager sharedManager];
}

- (RACSignal *)signal
{
    return self.subject;
}

- (void)addText:(NSString *)text
{
    DBTable *itemsTable = [self.defaultDatastore getTable:@"items"];
    NSDate *now = [NSDate date];
    /*DBRecord *itemRecord =*/ [itemsTable insert:@{ @"text": text, @"createDate": now, @"orderDate": now}];
    [self.defaultDatastore sync:nil];
    NSLog(@"AddText: %@", text);
    [self.subject sendNext:nil];
}

- (void)removeItemAtIndex:(NSInteger)index
{
    DBRecord *record = self.items[index];
    [record deleteRecord];
    [self.defaultDatastore sync:nil];
}

- (NSArray *)items
{
    DBTable *itemsTable = [self.defaultDatastore getTable:@"items"];
    DBError *error = nil;
    NSArray *records = [itemsTable query:nil error:&error];
    if (error) {
        NSLog(@"query items failed: %@", error);
    }
    return [records sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"orderDate" ascending:NO]]];
}

- (void)addDeviceToken:(NSString *)deviceToken
{
    DBTable *table = [self.defaultDatastore getTable:@"deviceTokens"];
    DBError *error = nil;
    BOOL inserted;
    NSDate *now = [NSDate date];
    NSDictionary *newFields = @{
        @"createDate": now,
    };
    DBRecord *record = [table getOrInsertRecord:deviceToken fields:newFields inserted:&inserted error:&error];
    if (error) {
        NSLog(@"getOrInsertRecord deviceToken failed: %@", error);
    }
    NSDictionary *updateFields = @{
        @"name": [[UIDevice currentDevice] name],
        @"device": [[UIDevice currentDevice] model],
        @"orderDate": now
    };
    [record update:updateFields];
    [self.defaultDatastore sync:nil];
    NSLog(@"deviceToken: %@ inserted: %hhd", deviceToken, inserted);
}


#pragma mark - private

- (DBDatastore *)defaultDatastore
{
    if (!_defaultDatastore) {
        DBError *error = nil;
        _defaultDatastore = [[self sharedDatastoreManager] openDefaultDatastore:&error];
        if (error) {
            NSLog(@"openDefaultDatastore failed: %@", error);
        }
//        [_defaultDatastore sync:&error];
//        if (error) {
//            NSLog(@"defaultDatastore sync failed: %@", error);
//        }
        __weak typeof(self) weakSelf = self;
        [_defaultDatastore addObserver:self block:^{
            NSLog(@"observe");
            // This condition prevent canceling UITableViewCell delete animation by reloadData
            if (weakSelf.defaultDatastore.status.incoming) {
                [weakSelf.defaultDatastore sync:nil];
                [weakSelf.subject sendNext:nil];
            }
        }];
    }
    return _defaultDatastore;
}

@end
