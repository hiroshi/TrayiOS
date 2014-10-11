#import "TrayModel.h"
#import <Dropbox/Dropbox.h>
#import "Secrets.h"

@implementation TrayModel

+ (void)setupDropbox
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

+ (void)loginFromViewController:(UIViewController *)viewController
{
    DBAccount *account = [[DBAccountManager sharedManager] linkedAccount];
    if (account) {
        NSLog(@"App already linked");
    } else {
        [[DBAccountManager sharedManager] linkFromController:viewController];
    }
}

+ (BOOL)handleOpenURL:(NSURL *)url
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

+ (DBDatastoreManager *)sharedManager
{
    if (![DBDatastoreManager sharedManager]) {
        [self setupDropbox];
    }
    return [DBDatastoreManager sharedManager];
}

+ (void)addText:(NSString *)text
{
//    DBDatastore *datastore = [[self sharedManager] openDefaultDatastore:nil];
    DBError *error = nil;
    //DBDatastore *datastore = [[self sharedManager] openDatastore:DROPBOX_SHARED_QUEUE_DSID error:&error];
    DBDatastore *datastore = [[self sharedManager] openDefaultDatastore:&error];
    if (error) {
        NSLog(@"openDatastore:%@ error:%@", @"default", error);
    }
    DBTable *itemsTable = [datastore getTable:@"items"];
    DBRecord *itemRecord = [itemsTable insert:@{ @"text": text}];
    [datastore sync:nil];
    NSLog(@"AddText: %@", text);
}

@end
