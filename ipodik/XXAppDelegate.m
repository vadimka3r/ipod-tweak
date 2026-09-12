#import "XXAppDelegate.h"
#import "XXCalculatorViewController.h"
#import "XXBrowserViewController.h"

@implementation XXAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    _window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];

    XXCalculatorViewController *calcVC = [[XXCalculatorViewController alloc] init];
    calcVC.title = @"Calculator";
    calcVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Calculator" image:nil tag:0];

    XXBrowserViewController *browserVC = [[XXBrowserViewController alloc] init];
    browserVC.title = @"Browser";
    browserVC.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"Browser" image:nil tag:1];

    _tabBarController = [[UITabBarController alloc] init];
    _tabBarController.viewControllers = @[calcVC, browserVC];

    _window.rootViewController = _tabBarController;
    [_window makeKeyAndVisible];
    return YES;
}

@end
