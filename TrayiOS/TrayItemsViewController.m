#import "TrayItemsViewController.h"
#import <ReactiveCocoa.h>
#import <Dropbox/Dropbox.h>
#import <TUSafariActivity.h>
#import "TrayModel.h"
#import "TrayTextViewController.h"

@interface TrayItemsViewController ()

@end

@implementation TrayItemsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    // Add item button
    UIBarButtonItem *addButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:nil action:nil];
    addButtonItem.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        //[TrayModel addText:[[NSDate date] description]];
        UIViewController *viewController = [TrayTextViewController new];
        [self.navigationController pushViewController:viewController animated:YES];
        return [RACSignal empty];
    }];
    self.navigationItem.rightBarButtonItem = addButtonItem;
    
    [[TrayModel sharedModel].signal subscribeNext:^(id x) {
        NSLog(@"reloadData");
        [self.tableView reloadData];
    }];
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [TrayModel sharedModel].items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    DBRecord *record = [TrayModel sharedModel].items[indexPath.row];
    NSString *text = record[@"text"];
    cell.textLabel.text = text;
    // Remove old gestureRecognizers from the possible reused cell.
    for (UIGestureRecognizer *gesture in cell.gestureRecognizers) {
        [cell removeGestureRecognizer:gesture];
    }
    UILongPressGestureRecognizer *gesture = [UILongPressGestureRecognizer new];
    [gesture.rac_gestureSignal subscribeNext:^(UILongPressGestureRecognizer *gesture) {
        if (gesture.state == UIGestureRecognizerStateBegan) {
            NSError *error = nil;
            NSDataDetector* detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:&error];
            if (error) {
                NSLog(@"dataDetectorWithTypes:error:%@", error);
            }
            NSMutableArray *activityItems = [NSMutableArray arrayWithObject:text];
            [detector enumerateMatchesInString:text options:0 range:NSMakeRange(0, text.length) usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                [activityItems addObject:[NSURL URLWithString:[text substringWithRange:result.range]]];
                *stop = YES;
            }];
            NSLog(@"activityItems: %@", activityItems);
            UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:@[[TUSafariActivity new]]];
            [self presentViewController:activityViewController animated:YES completion:^{
                NSLog(@"present activityViewController completed.");
            }];
        }
    }];
    [cell addGestureRecognizer:gesture];
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Archive";
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [[TrayModel sharedModel] removeItemAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
