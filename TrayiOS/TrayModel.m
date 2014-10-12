#import "TrayModel.h"
#import <Dropbox/Dropbox.h>
#import <ReactiveCocoa.h>
#import "Secrets.h"

@interface TrayModel ()

@property (nonatomic, strong) DBDatastore *defaultDatastore;
@property (nonatomic, strong) RACSubject *subject;

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

- (void)setupDropbox
{
    // Set up the account manager
    DBAccountManager *accountManager = [[DBAccountManager alloc] initWithAppKey:DROPBOX_APP_KEY secret:DROPBOX_APP_SECRET];
    [DBAccountManager setSharedManager:accountManager];
    // Set up the datastore manager
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    if (account) {
        // Use Dropbox datastores
        [DBDatastoreManager setSharedManager:[DBDatastoreManager managerForAccount:account]];
    } else {
        // Use local datastores
        //[DBDatastoreManager setSharedManager:[DBDatastoreManager localManagerForAccountManager:[DBAccountManager sharedManager]]];
        UIViewController *viewController = ((UIWindow *)[UIApplication sharedApplication].windows[0]).rootViewController;
        [self loginFromViewController:viewController];
    }
}

- (void)loginFromViewController:(UIViewController *)viewController
{
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    if (account) {
        NSLog(@"App already linked");
    } else {
        [[DBAccountManager sharedManager] linkFromController:viewController];
    }
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

- (DBDatastoreManager *)sharedManager
{
    if (![DBDatastoreManager sharedManager]) {
        [self setupDropbox];
    }
    return [DBDatastoreManager sharedManager];
}

- (void)addText:(NSString *)text
{
//    DBDatastore *datastore = [[self sharedManager] openDefaultDatastore:nil];
    //DBError *error = nil;
    //DBDatastore *datastore = [[self sharedManager] openDatastore:DROPBOX_SHARED_QUEUE_DSID error:&error];
//    DBDatastore *datastore = [[self sharedManager] openDefaultDatastore:&error];
//    if (error) {
//        NSLog(@"openDatastore:%@ error:%@", @"default", error);
//    }
    DBTable *itemsTable = [self.defaultDatastore getTable:@"items"];
    /*DBRecord *itemRecord =*/ [itemsTable insert:@{ @"text": text}];
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
    return [records.rac_sequence map:^id(DBRecord *record) {
        return record.fields;
    }].array;
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
        self.defaultDatastore = [[self sharedManager] openDefaultDatastore:&error];
        if (error) {
            NSLog(@"openDefaultDatastore failed: %@", error);
        }
    }
    return _defaultDatastore;
}

@end
