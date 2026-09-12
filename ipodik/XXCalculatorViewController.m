#import "XXCalculatorViewController.h"

@interface XXCalculatorViewController ()
@property (nonatomic, strong) UILabel *display;
@property (nonatomic, strong) NSString *currentInput;
@property (nonatomic) double storedValue;
@property (nonatomic, strong) NSString *pendingOperation;
@end

@implementation XXCalculatorViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    self.currentInput = @"0";

    self.display = [[UILabel alloc] initWithFrame:CGRectMake(10, 40, self.view.bounds.size.width - 20, 60)];
    self.display.textAlignment = NSTextAlignmentRight;
    self.display.textColor = [UIColor whiteColor];
    self.display.font = [UIFont systemFontOfSize:40];
    self.display.text = @"0";
    self.display.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.display];

    NSArray *buttonTitles = @[
        @"7", @"8", @"9", @"/",
        @"4", @"5", @"6", @"*",
        @"1", @"2", @"3", @"-",
        @"C", @"0", @"=", @"+"
    ];

    CGFloat buttonSize = 60;
    CGFloat margin = 8;
    CGFloat startY = 120;
    int cols = 4;

    for (int i = 0; i < buttonTitles.count; i++) {
        int row = i / cols;
        int col = i % cols;
        CGFloat x = margin + col * (buttonSize + margin);
        CGFloat y = startY + row * (buttonSize + margin);

        UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        btn.frame = CGRectMake(x, y, buttonSize, buttonSize);
        [btn setTitle:buttonTitles[i] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:22];
        btn.backgroundColor = [UIColor darkGrayColor];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.layer.cornerRadius = 8;
        [btn addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:btn];
    }
}

- (void)buttonTapped:(UIButton *)sender {
    NSString *title = [sender titleForState:UIControlStateNormal];

    if ([title isEqualToString:@"C"]) {
        self.currentInput = @"0";
        self.storedValue = 0;
        self.pendingOperation = nil;
    } else if ([title isEqualToString:@"+"] || [title isEqualToString:@"-"] ||
               [title isEqualToString:@"*"] || [title isEqualToString:@"/"]) {
        self.storedValue = [self.currentInput doubleValue];
        self.pendingOperation = title;
        self.currentInput = @"0";
    } else if ([title isEqualToString:@"="]) {
        double second = [self.currentInput doubleValue];
        double result = 0;
        if ([self.pendingOperation isEqualToString:@"+"]) result = self.storedValue + second;
        else if ([self.pendingOperation isEqualToString:@"-"]) result = self.storedValue - second;
        else if ([self.pendingOperation isEqualToString:@"*"]) result = self.storedValue * second;
        else if ([self.pendingOperation isEqualToString:@"/"]) result = second != 0 ? self.storedValue / second : 0;
        self.currentInput = [NSString stringWithFormat:@"%g", result];
        self.pendingOperation = nil;
    } else {
        if ([self.currentInput isEqualToString:@"0"]) {
            self.currentInput = title;
        } else {
            self.currentInput = [self.currentInput stringByAppendingString:title];
        }
    }

    self.display.text = self.currentInput;
}

@end
