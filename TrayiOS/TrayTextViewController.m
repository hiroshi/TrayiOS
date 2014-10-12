#import "TrayTextViewController.h"
#import <ReactiveCocoa.h>
#import <RACEXTScope.h>
#import "TrayModel.h"

@interface TrayTextViewController ()

@property (nonatomic, strong) UITextView *textView;

@end

@implementation TrayTextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // textView
    UITextView *textView = [[UITextView alloc] initWithFrame:self.view.frame];
    textView.font = [UIFont systemFontOfSize:20];
    textView.text = [[NSDate date] description];
    [self.view addSubview:textView];
    self.textView = textView;
    // saveButton
    UIBarButtonItem *saveButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Save" style:UIBarButtonItemStylePlain target:nil action:nil];
    @weakify(self);
    saveButtonItem.rac_command = [[RACCommand alloc] initWithSignalBlock:^RACSignal *(id input) {
        @strongify(self);
        [[TrayModel sharedModel] addText:self.textView.text];
        [self.navigationController popViewControllerAnimated:YES];
        return [RACSignal empty];
    }];
    self.navigationItem.rightBarButtonItem = saveButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
