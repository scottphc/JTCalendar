//
//  JTCalendarDayView.m
//  JTCalendar
//
//  Created by Jonathan Tribouharet
//

#import "JTCalendarDayView.h"

#import "JTCircleView.h"

@interface JTCalendarDayView (){
    UIView *backgroundView;
    JTCircleView *circleView;
    UILabel *textLabel;
    NSArray *dotViews;
    
    BOOL isSelected;
    
    int cacheIsToday;
    NSString *cacheCurrentDateText;
}
@end

static NSString *const kJTCalendarDaySelected = @"kJTCalendarDaySelected";

@implementation JTCalendarDayView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if(!self){
        return nil;
    }
    
    [self commonInit];
    
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(!self){
        return nil;
    }
    
    [self commonInit];
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter]  removeObserver:self];
}

- (void)commonInit
{
    isSelected = NO;
    self.isOtherMonth = NO;

    {
        backgroundView = [UIView new];
        [self addSubview:backgroundView];
    }
    
    {
        circleView = [JTCircleView new];
        [self addSubview:circleView];
    }
    
    {
        textLabel = [UILabel new];
        [self addSubview:textLabel];
    }
    
    NSMutableArray *temp = [NSMutableArray array];
    {
        JTCircleView *dotView = [JTCircleView new];
        [self addSubview:dotView];
        dotView.hidden = YES;
        [temp addObject:dotView];
    }
    
    {
        JTCircleView *dotView = [JTCircleView new];
        [self addSubview:dotView];
        dotView.hidden = YES;
        [temp addObject:dotView];
    }
    
    {
        JTCircleView *dotView = [JTCircleView new];
        [self addSubview:dotView];
        dotView.hidden = YES;
        [temp addObject:dotView];
    }
    dotViews = temp;
    
    {
        UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTouch)];

        self.userInteractionEnabled = YES;
        [self addGestureRecognizer:gesture];
    }
    
    {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didDaySelected:) name:kJTCalendarDaySelected object:nil];
    }
}

- (void)layoutSubviews
{
    [self configureConstraintsForSubviews];
    
    // No need to call [super layoutSubviews]
}

// Avoid to calcul constraints (very expensive)
- (void)configureConstraintsForSubviews
{
    textLabel.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    backgroundView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);


    CGFloat sizeCircle = MIN(self.frame.size.width, self.frame.size.height);
    CGFloat sizeDot = sizeCircle;
    
    sizeCircle = sizeCircle * self.calendarManager.calendarAppearance.dayCircleRatio;
    sizeDot = sizeDot * self.calendarManager.calendarAppearance.dayDotRatio;
    
    sizeCircle = roundf(sizeCircle);
    sizeDot = roundf(sizeDot);
    
    circleView.frame = CGRectMake(0, 0, sizeCircle, sizeCircle);
    circleView.center = CGPointMake(self.frame.size.width / 2., self.frame.size.height / 2.);
    circleView.layer.cornerRadius = sizeCircle / 2.;
    
    ((JTCircleView *)dotViews[0]).frame = CGRectMake(sizeDot*2, sizeDot*2, sizeDot, sizeDot);
    ((JTCircleView *)dotViews[1]).frame = CGRectMake(sizeDot*2, sizeDot*2, sizeDot, sizeDot);
    ((JTCircleView *)dotViews[2]).frame = CGRectMake(sizeDot*2, sizeDot*2, sizeDot, sizeDot);
    
    JTCircleView *dotView0, *dotView1, *dotView2;
    NSInteger count = 0;
    
    for (JTCircleView *dotView in dotViews) {
        if (dotView.hidden == NO) {
            if (count == 0) {
                dotView0 = dotView;
            } else if (count == 1) {
                dotView1 = dotView;
            } else if (count == 2) {
                dotView2 = dotView;
            }
            count++;
        }
    }
    
    if (count == 3) {
        dotView1.center = CGPointMake(self.frame.size.width / 2., (self.frame.size.height / 2.) +dotView1.frame.size.height * 2.5);
        dotView0.center = CGPointMake(self.frame.size.width / 2. - dotView0.frame.size.width * 1.5, (self.frame.size.height / 2.) +dotView0.frame.size.height * 2.5);
        dotView2.center = CGPointMake(self.frame.size.width / 2. + dotView2.frame.size.width * 1.5, (self.frame.size.height / 2.) +dotView2.frame.size.height * 2.5);
    } else if (count == 2) {
        dotView0.center = CGPointMake(self.frame.size.width / 2. - dotView0.frame.size.width, (self.frame.size.height / 2.) +dotView0.frame.size.height * 2.5);
        dotView1.center = CGPointMake(self.frame.size.width / 2. + dotView1.frame.size.width, (self.frame.size.height / 2.) +dotView1.frame.size.height * 2.5);
    } else if (count == 1) {
        dotView0.center = CGPointMake(self.frame.size.width / 2., (self.frame.size.height / 2.) +dotView0.frame.size.height * 2.5);
    }
    
    ((JTCircleView *)dotViews[0]).layer.cornerRadius = sizeDot / 2.;
    ((JTCircleView *)dotViews[1]).layer.cornerRadius = sizeDot / 2.;
    ((JTCircleView *)dotViews[2]).layer.cornerRadius = sizeDot / 2.;
}

- (void)setDate:(NSDate *)date
{
    static NSDateFormatter *dateFormatter;
    if(!dateFormatter){
        dateFormatter = [NSDateFormatter new];
        dateFormatter.timeZone = self.calendarManager.calendarAppearance.calendar.timeZone;
        [dateFormatter setDateFormat:self.calendarManager.calendarAppearance.dayFormat];
    }
    
    self->_date = date;
    
    textLabel.text = [dateFormatter stringFromDate:date];
    
    cacheIsToday = -1;
    cacheCurrentDateText = nil;
}

- (void)didTouch
{
    if([self.calendarManager.dataSource respondsToSelector:@selector(calendar:canSelectDate:)]){
        if(![self.calendarManager.dataSource calendar:self.calendarManager canSelectDate:self.date]){
            return;
        }
    }
    
    [self setSelected:YES animated:YES];
    [self.calendarManager setCurrentDateSelected:self.date];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kJTCalendarDaySelected object:self.date];
    
    [self.calendarManager.dataSource calendarDidDateSelected:self.calendarManager date:self.date];
    
    if(!self.isOtherMonth || !self.calendarManager.calendarAppearance.autoChangeMonth){
        return;
    }
    
    NSInteger currentMonthIndex = [self monthIndexForDate:self.date];
    NSInteger calendarMonthIndex = [self monthIndexForDate:self.calendarManager.currentDate];
        
    currentMonthIndex = currentMonthIndex % 12;
    
    if(currentMonthIndex == (calendarMonthIndex + 1) % 12){
        [self.calendarManager loadNextPage];
    }
    else if(currentMonthIndex == (calendarMonthIndex + 12 - 1) % 12){
        [self.calendarManager loadPreviousPage];
    }
}

- (void)didDaySelected:(NSNotification *)notification
{
    NSDate *dateSelected = [notification object];
    
    if([self isSameDate:dateSelected]){
        if(!isSelected){
            [self setSelected:YES animated:YES];
        }
    }
    else if(isSelected){
        [self setSelected:NO animated:YES];
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if(isSelected == selected){
        animated = NO;
    }
    
    isSelected = selected;
    
    circleView.transform = CGAffineTransformIdentity;
    CGAffineTransform tr = CGAffineTransformIdentity;
    CGFloat opacity = 1.;
    
    if(selected){
        if(!self.isOtherMonth){
            circleView.color = [self.calendarManager.calendarAppearance dayCircleColorSelected];
            textLabel.textColor = [self.calendarManager.calendarAppearance dayTextColorSelected];
//            dotView.color = [self.calendarManager.calendarAppearance dayDotColorSelected];
        }
        else{
            circleView.color = [self.calendarManager.calendarAppearance dayCircleColorSelectedOtherMonth];
            textLabel.textColor = [self.calendarManager.calendarAppearance dayTextColorSelectedOtherMonth];
//            dotView.color = [self.calendarManager.calendarAppearance dayDotColorSelectedOtherMonth];
        }
        
        circleView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.1, 0.1);
        tr = CGAffineTransformIdentity;
    }
    else if([self isToday]){
        if(!self.isOtherMonth){
            circleView.color = [self.calendarManager.calendarAppearance dayCircleColorToday];
            textLabel.textColor = [self.calendarManager.calendarAppearance dayTextColorToday];
//            dotView.color = [self.calendarManager.calendarAppearance dayDotColorToday];
        }
        else{
            circleView.color = [self.calendarManager.calendarAppearance dayCircleColorTodayOtherMonth];
            textLabel.textColor = [self.calendarManager.calendarAppearance dayTextColorTodayOtherMonth];
//            dotView.color = [self.calendarManager.calendarAppearance dayDotColorTodayOtherMonth];
        }
    }
    else{
        if(!self.isOtherMonth){
            textLabel.textColor = [self.calendarManager.calendarAppearance dayTextColor];
//            dotView.color = [self.calendarManager.calendarAppearance dayDotColor];
        }
        else{
            textLabel.textColor = [self.calendarManager.calendarAppearance dayTextColorOtherMonth];
//            dotView.color = [self.calendarManager.calendarAppearance dayDotColorOtherMonth];
        }
        
        opacity = 0.;
    }
    
    if(animated){
        [UIView animateWithDuration:.3 animations:^{
            circleView.layer.opacity = opacity;
            circleView.transform = tr;
        }];
    }
    else{
        circleView.layer.opacity = opacity;
        circleView.transform = tr;
    }
}

- (void)setIsOtherMonth:(BOOL)isOtherMonth
{
    self->_isOtherMonth = isOtherMonth;
    [self setSelected:isSelected animated:NO];
}

- (void)reloadData
{
    NSInteger bitShift = [self.calendarManager.dataCache haveEvent:self.date]; // 111, transfer/income/expense
    NSInteger count = 0;
    
    JTCircleView *dotView0, *dotView1, *dotView2;
    if (bitShift % 2 == 1) {
        dotView0 = dotViews[0];
        [(JTCircleView *)dotViews[0] setHidden:NO];
        count++;
    } else
        [(JTCircleView *)dotViews[0] setHidden:YES];
    
    bitShift = bitShift >> 1;
    
    if (bitShift % 2 == 1) {
        if (dotView0) {
            dotView1 = dotViews[1];
        } else
            dotView0 = dotViews[1];
        
        [(JTCircleView *)dotViews[1] setHidden:NO];
        count++;
    } else
        [(JTCircleView *)dotViews[1] setHidden:YES];
    
    bitShift = bitShift >> 1;
    
    if (bitShift % 2 == 1) {
        if (dotView0) {
            if (dotView1) {
                dotView2 = dotViews[2];
            } else
                dotView1 = dotViews[2];
        } else
            dotView0 = dotViews[2];
        
        [(JTCircleView *)dotViews[2] setHidden:NO];
        count++;
    } else
        [(JTCircleView *)dotViews[2] setHidden:YES];
    
    if (count == 3) {
        dotView1.center = CGPointMake(self.frame.size.width / 2., (self.frame.size.height / 2.) +dotView1.frame.size.height * 2.5);
        dotView0.center = CGPointMake(self.frame.size.width / 2. - dotView0.frame.size.width * 1.5, (self.frame.size.height / 2.) +dotView0.frame.size.height * 2.5);
        dotView2.center = CGPointMake(self.frame.size.width / 2. + dotView2.frame.size.width * 1.5, (self.frame.size.height / 2.) +dotView2.frame.size.height * 2.5);
    } else if (count == 2) {
        dotView0.center = CGPointMake(self.frame.size.width / 2. - dotView0.frame.size.width, (self.frame.size.height / 2.) +dotView0.frame.size.height * 2.5);
        dotView1.center = CGPointMake(self.frame.size.width / 2. + dotView1.frame.size.width, (self.frame.size.height / 2.) +dotView1.frame.size.height * 2.5);
    } else if (count == 1) {
        dotView0.center = CGPointMake(self.frame.size.width / 2., (self.frame.size.height / 2.) +dotView0.frame.size.height * 2.5);
    }
    
    BOOL selected = [self isSameDate:[self.calendarManager currentDateSelected]];
    [self setSelected:selected animated:NO];
}

- (BOOL)isToday
{
    if(cacheIsToday == 0){
        return NO;
    }
    else if(cacheIsToday == 1){
        return YES;
    }
    else{
        if([self isSameDate:[NSDate date]]){
            cacheIsToday = 1;
            return YES;
        }
        else{
            cacheIsToday = 0;
            return NO;
        }
    }
}

- (BOOL)isSameDate:(NSDate *)date
{
    static NSDateFormatter *dateFormatter;
    if(!dateFormatter){
        dateFormatter = [NSDateFormatter new];
        dateFormatter.timeZone = self.calendarManager.calendarAppearance.calendar.timeZone;
        [dateFormatter setDateFormat:@"dd-MM-yyyy"];
    }
    
    if(!cacheCurrentDateText){
        cacheCurrentDateText = [dateFormatter stringFromDate:self.date];
    }
    
    NSString *dateText2 = [dateFormatter stringFromDate:date];
    
    if ([cacheCurrentDateText isEqualToString:dateText2]) {
        return YES;
    }
    
    return NO;
}

- (NSInteger)monthIndexForDate:(NSDate *)date
{
    NSCalendar *calendar = self.calendarManager.calendarAppearance.calendar;
    NSDateComponents *comps = [calendar components:NSCalendarUnitMonth fromDate:date];
    return comps.month;
}

- (void)reloadAppearance
{
    textLabel.textAlignment = NSTextAlignmentCenter;
    textLabel.font = self.calendarManager.calendarAppearance.dayTextFont;
    backgroundView.backgroundColor = self.calendarManager.calendarAppearance.dayBackgroundColor;
    backgroundView.layer.borderWidth = self.calendarManager.calendarAppearance.dayBorderWidth;
    backgroundView.layer.borderColor = self.calendarManager.calendarAppearance.dayBorderColor.CGColor;
    
    [dotViews[0] setColor:self.calendarManager.calendarAppearance.expenseColor];
    [dotViews[1] setColor:self.calendarManager.calendarAppearance.incomeColor];
    [dotViews[2] setColor:self.calendarManager.calendarAppearance.transferColor];
    
    [self configureConstraintsForSubviews];
    [self setSelected:isSelected animated:NO];
}

@end
