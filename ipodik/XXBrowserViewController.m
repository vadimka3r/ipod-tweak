#import "XXBrowserViewController.h"

@interface XXBrowserViewController ()
@property (nonatomic, strong) UIWebView *webView;
@property (nonatomic, strong) UITextField *addressField;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *forwardButton;
@end

@implementation XXBrowserViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];

    CGFloat topBarHeight = 40;
    CGFloat width = self.view.bounds.size.width;

    self.addressField = [[UITextField alloc] initWithFrame:CGRectMake(5, 5, width - 10, 30)];
    self.addressField.borderStyle = UITextBorderStyleRoundedRect;
    self.addressField.placeholder = @"http://example.com";
    self.addressField.keyboardType = UIKeyboardTypeURL;
    self.addressField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.addressField.delegate = self;
    self.addressField.text = @"http://example.com";
    [self.view addSubview:self.addressField];

    self.backButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.backButton.frame = CGRectMake(5, topBarHeight + 5, 60, 30);
    [self.backButton setTitle:@"< Back" forState:UIControlStateNormal];
    [self.backButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.backButton];

    self.forwardButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.forwardButton.frame = CGRectMake(70, topBarHeight + 5, 80, 30);
    [self.forwardButton setTitle:@"Forward >" forState:UIControlStateNormal];
    [self.forwardButton addTarget:self action:@selector(goForward) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.forwardButton];

    CGFloat webTop = topBarHeight + 45;
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, webTop, width, self.view.bounds.size.height - webTop)];
    self.webView.delegate = self;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.webView];

    [self loadURLString:@"http://example.com"];
}

- (void)loadURLString:(NSString *)urlString {
    NSURL *url = [NSURL URLWithString:urlString];
    if (url) {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [self.webView loadRequest:request];
    }
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self loadURLString:textField.text];
    return YES;
}

- (void)goBack {
    if ([self.webView canGoBack]) [self.webView goBack];
}

- (void)goForward {
    if ([self.webView canGoForward]) [self.webView goForward];
}

@end
