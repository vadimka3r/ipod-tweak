#import <UIKit/UIKit.h>
#import <objc/runtime.h>

static CGPoint startPoint;
static BOOL tracking;
static const void *kCustomizedKey = &kCustomizedKey;
static const void *kOurViewKey = &kOurViewKey;
static const void *kClockCustomizedKey = &kClockCustomizedKey;
static const void *kChargingCustomizedKey = &kChargingCustomizedKey;
static const void *kMenuCustomizedKey = &kMenuCustomizedKey;
static const void *kBgKey = &kBgKey;
static const void *kResultLabelKey = &kResultLabelKey;
static const void *kDiceViewKey = &kDiceViewKey;
static const void *kOrigSuperviewKey = &kOrigSuperviewKey;
static const void *kOrigFrameKey = &kOrigFrameKey;
static const void *kDrawerKey = &kDrawerKey;
static const void *kDrawerIconsKey = &kDrawerIconsKey;
static const void *kDrawerBtnDoneKey = &kDrawerBtnDoneKey;

static int tapCount = 0;
static NSTimeInterval lastTapTime = 0;

#define ACCENT [UIColor colorWithRed:0.35 green:0.85 blue:0.75 alpha:1.0]
#define CARD_BG [UIColor colorWithWhite:1.0 alpha:0.10]
#define TEXT_DIM [UIColor colorWithWhite:1.0 alpha:0.55]

static void baza_collectIconViews(UIView *view, NSMutableArray *out) {
    if ([NSStringFromClass([view class]) isEqualToString:@"SBIconView"]) {
        [out addObject:view];
    }
    for (UIView *sub in view.subviews) {
        baza_collectIconViews(sub, out);
    }
}

%hook SBAwayLockBar

- (void)layoutSubviews {
    %orig;
    UIView *me = (UIView *)self;
    for (UIView *sub in me.subviews) {
        if (objc_getAssociatedObject(sub, kOurViewKey)) continue;
        sub.hidden = YES;
        sub.alpha = 0;
    }
    me.backgroundColor = [UIColor clearColor];
    me.layer.contents = nil;
    NSNumber *done = objc_getAssociatedObject(self, kCustomizedKey);
    if (![done boolValue]) {
        objc_setAssociatedObject(self, kCustomizedKey, @YES, OBJC_ASSOCIATION_RETAIN);
        UILabel *hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 30, me.bounds.size.width, 20)];
        hintLabel.textAlignment = NSTextAlignmentCenter;
        hintLabel.backgroundColor = [UIColor clearColor];
        hintLabel.textColor = [UIColor colorWithWhite:1.0 alpha:0.85];
        hintLabel.font = [UIFont systemFontOfSize:14];
        hintLabel.text = @"Смахните вверх для разблокировки";
        hintLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        objc_setAssociatedObject(hintLabel, kOurViewKey, @YES, OBJC_ASSOCIATION_RETAIN);
        [me addSubview:hintLabel];
        CGFloat cw = 28;
        UIView *chevronView = [[UIView alloc] initWithFrame:CGRectMake((me.bounds.size.width - cw) / 2, 4, cw, cw)];
        chevronView.backgroundColor = [UIColor clearColor];
        chevronView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        objc_setAssociatedObject(chevronView, kOurViewKey, @YES, OBJC_ASSOCIATION_RETAIN);
        CAShapeLayer *chevron = [CAShapeLayer layer];
        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:CGPointMake(4, 18)];
        [path addLineToPoint:CGPointMake(14, 6)];
        [path addLineToPoint:CGPointMake(24, 18)];
        chevron.path = path.CGPath;
        chevron.strokeColor = [UIColor colorWithWhite:1.0 alpha:0.9].CGColor;
        chevron.fillColor = [UIColor clearColor].CGColor;
        chevron.lineWidth = 3;
        chevron.lineCap = kCALineCapRound;
        chevron.lineJoin = kCALineJoinRound;
        [chevronView.layer addSublayer:chevron];
        [me addSubview:chevronView];
        CABasicAnimation *bounce = [CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
        bounce.fromValue = @(0);
        bounce.toValue = @(-8);
        bounce.duration = 0.8;
        bounce.autoreverses = YES;
        bounce.repeatCount = HUGE_VALF;
        bounce.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [chevronView.layer addAnimation:bounce forKey:@"bounce"];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UIView *me = (UIView *)self;
    UITouch *t = [touches anyObject];
    startPoint = [t locationInView:me.superview];
    tracking = YES;
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!tracking) return;
    UIView *me = (UIView *)self;
    UITouch *t = [touches anyObject];
    CGPoint cur = [t locationInView:me.superview];
    CGFloat dy = startPoint.y - cur.y;
    if (dy < 0) dy = 0;
    if (dy > 150) dy = 150;
    me.transform = CGAffineTransformMakeTranslation(0, -dy);
    me.alpha = 1.0 - (dy / 150.0) * 0.5;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (!tracking) return;
    tracking = NO;
    UIView *me = (UIView *)self;
    UITouch *t = [touches anyObject];
    CGPoint cur = [t locationInView:me.superview];
    CGFloat dy = startPoint.y - cur.y;
    if (dy > 60) {
        id target = self;
        [UIView animateWithDuration:0.25 animations:^{
            me.transform = CGAffineTransformMakeTranslation(0, -400);
            me.alpha = 0;
        } completion:^(BOOL finished){
            #pragma clang diagnostic push
            #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            if ([target respondsToSelector:@selector(unlock)]) {
                [target performSelector:@selector(unlock)];
            }
            #pragma clang diagnostic pop
            me.transform = CGAffineTransformIdentity;
            me.alpha = 1.0;
        }];
    } else {
        [UIView animateWithDuration:0.25 animations:^{
            me.transform = CGAffineTransformIdentity;
            me.alpha = 1.0;
        }];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    tracking = NO;
    UIView *me = (UIView *)self;
    [UIView animateWithDuration:0.25 animations:^{
        me.transform = CGAffineTransformIdentity;
        me.alpha = 1.0;
    }];
}

%end

%hook SBAwayView

- (void)layoutSubviews {
    %orig;
    UIView *me = (UIView *)self;
    for (UIView *sub in me.subviews) {
        NSString *cls = [NSStringFromClass([sub class]) lowercaseString];
        if ([cls rangeOfString:@"camera"].location != NSNotFound || [cls rangeOfString:@"grabber"].location != NSNotFound) {
            sub.hidden = YES;
            sub.alpha = 0;
        }
    }
}

%end

%hook SBAwayDateView

- (void)layoutSubviews {
    %orig;
    UIView *me = (UIView *)self;
    me.userInteractionEnabled = YES;
    me.backgroundColor = [UIColor clearColor];
    me.layer.contents = nil;
    me.layer.shadowOpacity = 0;
    me.opaque = NO;
    for (UIView *sub in me.subviews) {
        if (objc_getAssociatedObject(sub, kOurViewKey)) continue;
        sub.hidden = YES;
        sub.alpha = 0;
    }
    NSNumber *done = objc_getAssociatedObject(self, kClockCustomizedKey);
    if (![done boolValue]) {
        objc_setAssociatedObject(self, kClockCustomizedKey, @YES, OBJC_ASSOCIATION_RETAIN);
        UILabel *dateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 4, me.bounds.size.width, 22)];
        dateLabel.textAlignment = NSTextAlignmentCenter;
        dateLabel.backgroundColor = [UIColor clearColor];
        dateLabel.textColor = [UIColor whiteColor];
        dateLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:17];
        if (!dateLabel.font) dateLabel.font = [UIFont boldSystemFontOfSize:17];
        objc_setAssociatedObject(dateLabel, kOurViewKey, @YES, OBJC_ASSOCIATION_RETAIN);
        [me addSubview:dateLabel];
        UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 24, me.bounds.size.width, 72)];
        timeLabel.textAlignment = NSTextAlignmentCenter;
        timeLabel.backgroundColor = [UIColor clearColor];
        timeLabel.textColor = [UIColor whiteColor];
        timeLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:66];
        if (!timeLabel.font) timeLabel.font = [UIFont boldSystemFontOfSize:66];
        objc_setAssociatedObject(timeLabel, kOurViewKey, @YES, OBJC_ASSOCIATION_RETAIN);
        [me addSubview:timeLabel];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(baza_handleTap)];
        [me addGestureRecognizer:tap];
        void (^update)(void) = ^{
            NSDateFormatter *tf = [[NSDateFormatter alloc] init];
            [tf setDateFormat:@"HH:mm"];
            timeLabel.text = [tf stringFromDate:[NSDate date]];
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            [df setLocale:[NSLocale localeWithLocaleIdentifier:@"ru_RU"]];
            [df setDateFormat:@"EEEE, d MMMM"];
            NSString *dateStr = [df stringFromDate:[NSDate date]];
            if (dateStr.length > 0) {
                dateStr = [[[dateStr substringToIndex:1] uppercaseString] stringByAppendingString:[dateStr substringFromIndex:1]];
            }
            dateLabel.text = dateStr;
        };
        update();
        [NSTimer scheduledTimerWithTimeInterval:1.0 target:[NSBlockOperation blockOperationWithBlock:update] selector:@selector(main) userInfo:nil repeats:YES];
    }
}

%new
- (void)baza_handleTap {
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    if (now - lastTapTime > 1.0) {
        tapCount = 0;
    }
    lastTapTime = now;
    tapCount++;
    if (tapCount >= 5) {
        tapCount = 0;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                          message:@"Привет сладкий"
                                                         delegate:nil
                                                cancelButtonTitle:@"OK"
                                                otherButtonTitles:nil];
        [alert show];
    }
}

%end

%hook SBWallpaperView

- (void)setAlpha:(CGFloat)alpha {
    %orig(1.0);
}

%end

%hook SBAwayChargingView

- (void)layoutSubviews {
    %orig;
    UIView *me = (UIView *)self;
    for (UIView *sub in me.subviews) {
        if (objc_getAssociatedObject(sub, kOurViewKey)) continue;
        sub.hidden = YES;
        sub.alpha = 0;
    }
    me.backgroundColor = [UIColor clearColor];
    NSNumber *done = objc_getAssociatedObject(self, kChargingCustomizedKey);
    if (![done boolValue]) {
        objc_setAssociatedObject(self, kChargingCustomizedKey, @YES, OBJC_ASSOCIATION_RETAIN);
        CGFloat ringSize = 90;
        UIView *ring = [[UIView alloc] initWithFrame:CGRectMake((me.bounds.size.width - ringSize) / 2, (me.bounds.size.height - ringSize) / 2, ringSize, ringSize)];
        ring.backgroundColor = [UIColor clearColor];
        objc_setAssociatedObject(ring, kOurViewKey, @YES, OBJC_ASSOCIATION_RETAIN);
        CAShapeLayer *circle = [CAShapeLayer layer];
        UIBezierPath *circlePath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(4, 4, ringSize - 8, ringSize - 8)];
        circle.path = circlePath.CGPath;
        circle.strokeColor = [UIColor colorWithWhite:1.0 alpha:0.9].CGColor;
        circle.fillColor = [UIColor clearColor].CGColor;
        circle.lineWidth = 3;
        [ring.layer addSublayer:circle];
        CGFloat boltW = 24, boltH = 40;
        CAShapeLayer *bolt = [CAShapeLayer layer];
        UIBezierPath *boltPath = [UIBezierPath bezierPath];
        [boltPath moveToPoint:CGPointMake(boltW * 0.55, 0)];
        [boltPath addLineToPoint:CGPointMake(0, boltH * 0.58)];
        [boltPath addLineToPoint:CGPointMake(boltW * 0.42, boltH * 0.58)];
        [boltPath addLineToPoint:CGPointMake(boltW * 0.45, boltH)];
        [boltPath addLineToPoint:CGPointMake(boltW, boltH * 0.4)];
        [boltPath addLineToPoint:CGPointMake(boltW * 0.58, boltH * 0.4)];
        [boltPath closePath];
        bolt.path = boltPath.CGPath;
        bolt.fillColor = [UIColor whiteColor].CGColor;
        bolt.frame = CGRectMake((ringSize - boltW) / 2, (ringSize - boltH) / 2, boltW, boltH);
        [ring.layer addSublayer:bolt];
        [me addSubview:ring];
        CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
        pulse.fromValue = @(1.0);
        pulse.toValue = @(1.08);
        pulse.duration = 1.0;
        pulse.autoreverses = YES;
        pulse.repeatCount = HUGE_VALF;
        pulse.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        [ring.layer addAnimation:pulse forKey:@"pulse"];
    }
}

%end

@interface SBVoiceControlMenuedAlertDisplay : UIView
- (void)baza_buildUI;
- (void)baza_rollDice;
- (void)baza_spinRoulette;
- (void)baza_drawDiceFace:(int)face inView:(UIView *)diceView;
- (void)baza_flashDiceFace:(NSNumber *)face;
- (void)baza_settleDice:(NSNumber *)face;
- (void)baza_settleRoulette;
@end

%hook SBVoiceControlMenuedAlertDisplay

- (void)layoutSubviews {
    %orig;
    UIView *me = (UIView *)self;
    for (UIView *sub in me.subviews) {
        if (objc_getAssociatedObject(sub, kOurViewKey)) continue;
        sub.hidden = YES;
        sub.alpha = 0;
    }
    NSNumber *done = objc_getAssociatedObject(self, kMenuCustomizedKey);
    if (![done boolValue]) {
        objc_setAssociatedObject(self, kMenuCustomizedKey, @YES, OBJC_ASSOCIATION_RETAIN);
        [self baza_buildUI];
    }
    UIView *bg = objc_getAssociatedObject(self, kBgKey);
    bg.frame = me.bounds;
    CAGradientLayer *gl = (CAGradientLayer *)bg.layer.sublayers[0];
    gl.frame = bg.bounds;
}

%new
- (void)baza_buildUI {
    UIView *me = (UIView *)self;
    UIView *bg = [[UIView alloc] initWithFrame:me.bounds];
    bg.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    objc_setAssociatedObject(bg, kOurViewKey, @YES, OBJC_ASSOCIATION_RETAIN);
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = me.bounds;
    gradient.colors = @[(id)[UIColor colorWithRed:0.06 green:0.07 blue:0.1 alpha:1.0].CGColor,
                         (id)[UIColor colorWithRed:0.1 green:0.12 blue:0.16 alpha:1.0].CGColor];
    gradient.startPoint = CGPointMake(0, 0);
    gradient.endPoint = CGPointMake(0, 1);
    [bg.layer addSublayer:gradient];
    [me addSubview:bg];
    objc_setAssociatedObject(self, kBgKey, bg, OBJC_ASSOCIATION_RETAIN);
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 26, bg.bounds.size.width, 30)];
    title.textAlignment = NSTextAlignmentCenter;
    title.backgroundColor = [UIColor clearColor];
    title.textColor = [UIColor whiteColor];
    title.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:24];
    if (!title.font) title.font = [UIFont systemFontOfSize:24];
    title.text = @"Рандомайзер";
    [bg addSubview:title];
    UIView *displayArea = [[UIView alloc] initWithFrame:CGRectMake(0, 70, bg.bounds.size.width, 150)];
    displayArea.backgroundColor = [UIColor clearColor];
    [bg addSubview:displayArea];
    UIView *dice = [[UIView alloc] initWithFrame:CGRectMake(displayArea.bounds.size.width/2 - 44, 20, 88, 88)];
    dice.backgroundColor = [UIColor whiteColor];
    dice.layer.cornerRadius = 16;
    [displayArea addSubview:dice];
    objc_setAssociatedObject(self, kDiceViewKey, dice, OBJC_ASSOCIATION_RETAIN);
    [self baza_drawDiceFace:1 inView:dice];
    UILabel *resultLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 220, bg.bounds.size.width, 30)];
    resultLabel.textAlignment = NSTextAlignmentCenter;
    resultLabel.backgroundColor = [UIColor clearColor];
    resultLabel.textColor = ACCENT;
    resultLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:18];
    if (!resultLabel.font) resultLabel.font = [UIFont boldSystemFontOfSize:18];
    [bg addSubview:resultLabel];
    objc_setAssociatedObject(self, kResultLabelKey, resultLabel, OBJC_ASSOCIATION_RETAIN);
    UIButton *diceBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    diceBtn.frame = CGRectMake(28, 260, bg.bounds.size.width - 56, 46);
    [diceBtn setTitle:@"Бросить кубик" forState:UIControlStateNormal];
    diceBtn.backgroundColor = CARD_BG;
    [diceBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    diceBtn.layer.cornerRadius = 12;
    diceBtn.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:16];
    [diceBtn addTarget:self action:@selector(baza_rollDice) forControlEvents:UIControlEventTouchUpInside];
    [bg addSubview:diceBtn];
    UIButton *rouletteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    rouletteBtn.frame = CGRectMake(28, 314, bg.bounds.size.width - 56, 46);
    [rouletteBtn setTitle:@"Крутить рулетку" forState:UIControlStateNormal];
    rouletteBtn.backgroundColor = CARD_BG;
    [rouletteBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    rouletteBtn.layer.cornerRadius = 12;
    rouletteBtn.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Medium" size:16];
    [rouletteBtn addTarget:self action:@selector(baza_spinRoulette) forControlEvents:UIControlEventTouchUpInside];
    [bg addSubview:rouletteBtn];
}

%new
- (void)baza_drawDiceFace:(int)face inView:(UIView *)diceView {
    for (CALayer *layer in [diceView.layer.sublayers copy]) {
        [layer removeFromSuperlayer];
    }
    CGFloat dotSize = 14;
    CGFloat w = diceView.bounds.size.width;
    CGFloat h = diceView.bounds.size.height;
    NSArray *positions;
    CGPoint tl = CGPointMake(w * 0.25, h * 0.25);
    CGPoint tr = CGPointMake(w * 0.75, h * 0.25);
    CGPoint ml = CGPointMake(w * 0.25, h * 0.5);
    CGPoint mr = CGPointMake(w * 0.75, h * 0.5);
    CGPoint bl = CGPointMake(w * 0.25, h * 0.75);
    CGPoint br = CGPointMake(w * 0.75, h * 0.75);
    CGPoint center = CGPointMake(w * 0.5, h * 0.5);
    switch (face) {
        case 1: positions = @[[NSValue valueWithCGPoint:center]]; break;
        case 2: positions = @[[NSValue valueWithCGPoint:tl], [NSValue valueWithCGPoint:br]]; break;
        case 3: positions = @[[NSValue valueWithCGPoint:tl], [NSValue valueWithCGPoint:center], [NSValue valueWithCGPoint:br]]; break;
        case 4: positions = @[[NSValue valueWithCGPoint:tl], [NSValue valueWithCGPoint:tr], [NSValue valueWithCGPoint:bl], [NSValue valueWithCGPoint:br]]; break;
        case 5: positions = @[[NSValue valueWithCGPoint:tl], [NSValue valueWithCGPoint:tr], [NSValue valueWithCGPoint:center], [NSValue valueWithCGPoint:bl], [NSValue valueWithCGPoint:br]]; break;
        default: positions = @[[NSValue valueWithCGPoint:tl], [NSValue valueWithCGPoint:tr], [NSValue valueWithCGPoint:ml], [NSValue valueWithCGPoint:mr], [NSValue valueWithCGPoint:bl], [NSValue valueWithCGPoint:br]]; break;
    }
    for (NSValue *v in positions) {
        CGPoint p = [v CGPointValue];
        CAShapeLayer *dot = [CAShapeLayer layer];
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(p.x - dotSize/2, p.y - dotSize/2, dotSize, dotSize)];
        dot.path = path.CGPath;
        dot.fillColor = [UIColor colorWithWhite:0.1 alpha:1.0].CGColor;
        [diceView.layer addSublayer:dot];
    }
}

%new
- (void)baza_rollDice {
    UIView *dice = objc_getAssociatedObject(self, kDiceViewKey);
    UILabel *resultLabel = objc_getAssociatedObject(self, kResultLabelKey);
    resultLabel.text = @"";
    CABasicAnimation *spin = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    spin.fromValue = @(0);
    spin.toValue = @(M_PI * 4);
    spin.duration = 0.5;
    [dice.layer addAnimation:spin forKey:@"diceSpin"];
    for (int i = 1; i <= 6; i++) {
        [self performSelector:@selector(baza_flashDiceFace:) withObject:@(1 + arc4random() % 6) afterDelay:0.06 * i];
    }
    int finalFace = 1 + arc4random() % 6;
    [self performSelector:@selector(baza_settleDice:) withObject:@(finalFace) afterDelay:0.06 * 7];
}

%new
- (void)baza_flashDiceFace:(NSNumber *)face {
    UIView *dice = objc_getAssociatedObject(self, kDiceViewKey);
    [self baza_drawDiceFace:[face intValue] inView:dice];
}

%new
- (void)baza_settleDice:(NSNumber *)face {
    UIView *dice = objc_getAssociatedObject(self, kDiceViewKey);
    UILabel *resultLabel = objc_getAssociatedObject(self, kResultLabelKey);
    [self baza_drawDiceFace:[face intValue] inView:dice];
    resultLabel.text = [NSString stringWithFormat:@"Выпало: %d", [face intValue]];
    dice.transform = CGAffineTransformMakeScale(1.2, 1.2);
    [UIView animateWithDuration:0.3 animations:^{
        dice.transform = CGAffineTransformIdentity;
    }];
}

%new
- (void)baza_spinRoulette {
    UIView *dice = objc_getAssociatedObject(self, kDiceViewKey);
    UILabel *resultLabel = objc_getAssociatedObject(self, kResultLabelKey);
    resultLabel.text = @"";
    CABasicAnimation *spin = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    spin.fromValue = @(0);
    spin.toValue = @(M_PI * 8);
    spin.duration = 1.2;
    spin.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [dice.layer addAnimation:spin forKey:@"rouletteSpin"];
    [self performSelector:@selector(baza_settleRoulette) withObject:nil afterDelay:1.2];
}

%new
- (void)baza_settleRoulette {
    UILabel *resultLabel = objc_getAssociatedObject(self, kResultLabelKey);
    BOOL red = (arc4random() % 2 == 0);
    int number = arc4random() % 37;
    resultLabel.textColor = red ? [UIColor colorWithRed:0.9 green:0.3 blue:0.3 alpha:1.0] : [UIColor whiteColor];
    resultLabel.text = [NSString stringWithFormat:@"%d — %@", number, red ? @"Красное" : @"Чёрное"];
}

%end

@interface SBIconContentView : UIView
- (void)baza_showDrawer;
- (void)baza_hideDrawer;
@end

%hook SBIconContentView

- (void)layoutSubviews {
    %orig;
    UIView *me = (UIView *)self;

    NSNumber *done = objc_getAssociatedObject(self, kDrawerBtnDoneKey);
    if (![done boolValue]) {
        objc_setAssociatedObject(self, kDrawerBtnDoneKey, @YES, OBJC_ASSOCIATION_RETAIN);

        UIButton *drawerBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        drawerBtn.frame = CGRectMake(me.bounds.size.width - 54, me.bounds.size.height - 130, 44, 44);
        drawerBtn.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.4];
        [drawerBtn setTitle:@"⊞" forState:UIControlStateNormal];
        [drawerBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        drawerBtn.titleLabel.font = [UIFont systemFontOfSize:22];
        drawerBtn.layer.cornerRadius = 22;
        drawerBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
        [drawerBtn addTarget:self action:@selector(baza_showDrawer) forControlEvents:UIControlEventTouchUpInside];
        [me addSubview:drawerBtn];
    }
}

%new
- (void)baza_showDrawer {
    UIView *me = (UIView *)self;
    UIWindow *win = [[UIApplication sharedApplication] keyWindow];

    NSMutableArray *icons = [NSMutableArray array];
    baza_collectIconViews(me, icons);
    if (icons.count == 0) return;

    UIView *drawer = [[UIView alloc] initWithFrame:win.bounds];
    drawer.backgroundColor = [UIColor colorWithWhite:0.05 alpha:0.96];
    objc_setAssociatedObject(self, kDrawerKey, drawer, OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(self, kDrawerIconsKey, icons, OBJC_ASSOCIATION_RETAIN);

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(0, 10, win.bounds.size.width, 30)];
    title.textAlignment = NSTextAlignmentCenter;
    title.textColor = [UIColor whiteColor];
    title.backgroundColor = [UIColor clearColor];
    title.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
    if (!title.font) title.font = [UIFont systemFontOfSize:20];
    title.text = @"Приложения";
    [drawer addSubview:title];

    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    closeBtn.frame = CGRectMake(win.bounds.size.width - 60, 8, 50, 30);
    [closeBtn setTitle:@"Закрыть" forState:UIControlStateNormal];
    [closeBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    closeBtn.titleLabel.font = [UIFont systemFontOfSize:13];
    [closeBtn addTarget:self action:@selector(baza_hideDrawer) forControlEvents:UIControlEventTouchUpInside];
    [drawer addSubview:closeBtn];

    CGFloat cellSize = 64;
    CGFloat margin = 12;
    int cols = 4;
    CGFloat startX = (win.bounds.size.width - (cellSize * cols + margin * (cols - 1))) / 2;
    CGFloat startY = 50;

    for (NSUInteger i = 0; i < icons.count; i++) {
        UIView *icon = icons[i];

        UIView *originalSuperview = icon.superview;
        CGRect originalFrame = icon.frame;
        objc_setAssociatedObject(icon, kOrigSuperviewKey, originalSuperview, OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(icon, kOrigFrameKey, [NSValue valueWithCGRect:originalFrame], OBJC_ASSOCIATION_RETAIN);

        int row = (int)i / cols;
        int col = (int)i % cols;
        CGRect targetFrame = CGRectMake(startX + col * (cellSize + margin), startY + row * (cellSize + margin), cellSize, cellSize);

        [icon removeFromSuperview];
        icon.frame = targetFrame;
        [drawer addSubview:icon];
    }

    drawer.alpha = 0;
    [win addSubview:drawer];
    [UIView animateWithDuration:0.25 animations:^{
        drawer.alpha = 1;
    }];
}

%new
- (void)baza_hideDrawer {
    UIView *drawer = objc_getAssociatedObject(self, kDrawerKey);
    NSArray *icons = objc_getAssociatedObject(self, kDrawerIconsKey);
    if (!drawer || !icons) return;

    for (UIView *icon in icons) {
        UIView *originalSuperview = objc_getAssociatedObject(icon, kOrigSuperviewKey);
        CGRect originalFrame = [objc_getAssociatedObject(icon, kOrigFrameKey) CGRectValue];
        [icon removeFromSuperview];
        icon.frame = originalFrame;
        [originalSuperview addSubview:icon];
    }

    [UIView animateWithDuration:0.2 animations:^{
        drawer.alpha = 0;
    } completion:^(BOOL finished) {
        [drawer removeFromSuperview];
    }];

    objc_setAssociatedObject(self, kDrawerKey, nil, OBJC_ASSOCIATION_RETAIN);
    objc_setAssociatedObject(self, kDrawerIconsKey, nil, OBJC_ASSOCIATION_RETAIN);
}

%end
