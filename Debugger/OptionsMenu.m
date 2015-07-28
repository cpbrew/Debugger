//
//  OptionsMenu.m
//  Debugger
//
//  Created by Christopher Brew on 3/6/13.
//
//

#import "OptionsMenu.h"

#define DEFAULT_CELL_WIDTH  320
#define DEFAULT_CELL_HEIGHT 44

@implementation OptionsMenuBoolItem {
    NSString *_key;
    UISwitch *_switch;
    __weak id<OptionsMenuDelegate> _delegate;
}

@synthesize key = _key;

- (id)initWithKey:(NSString *)key initialValue:(BOOL)value delegate:(id<OptionsMenuDelegate>)delegate {
    if (self = [super init]) {
        _key = key;
        _delegate = delegate;
        
        _switch = [[UISwitch alloc] init];
        _switch.on = value;
        [_switch addTarget:self action:@selector(switchTriggered:) forControlEvents:UIControlEventValueChanged];
    }
    
    return self;
}

- (UIControl *)getControl {
    return _switch;
}

- (void)switchTriggered:(UIControl *)sender {
    if ([_delegate respondsToSelector:@selector(option:wasSwitchedTo:)]) {
        [_delegate option:_key wasSwitchedTo:[NSNumber numberWithBool:_switch.on]];
    }
}

@end


@implementation OptionsMenuSliderItem {
    NSString *_key;
    UISlider *_slider;
    __weak id<OptionsMenuDelegate> _delegate;
}

@synthesize key = _key;

- (id)initWithKey:(NSString *)key min:(int)min max:(int)max initialValue:(int)value delegate:(id<OptionsMenuDelegate>)delegate {
    if (self = [super init]) {
        _key = key;
        _delegate = delegate;
        
        _slider = [[UISlider alloc] init];
        _slider.minimumValue = min;
        _slider.maximumValue = max;
        _slider.value = value;
        [_slider addTarget:self action:@selector(sliderTriggered:) forControlEvents:UIControlEventValueChanged];
    }
    
    return self;
}

- (UIControl *)getControl {
    return _slider;
}

- (void)sliderTriggered:(UIControl *)sender {
    if ([_delegate respondsToSelector:@selector(option:wasSwitchedTo:)]) {
        [_delegate option:_key wasSwitchedTo:[NSNumber numberWithInt:_slider.value]];
    }
}

@end


@implementation OptionsMenuSegmentedItem {
    NSString *_key;
    UISegmentedControl *_segmentedControl;
    __weak id<OptionsMenuDelegate> _delegate;
}

@synthesize key = _key;

- (id)initWithKey:(NSString *)key items:(NSArray *)items initialValue:(NSString *)value delegate:(id<OptionsMenuDelegate>)delegate {
    if (self = [super init]) {
        _key = key;
        _delegate = delegate;
        
        _segmentedControl = [[UISegmentedControl alloc] initWithItems:items];
        _segmentedControl.selectedSegmentIndex = [items indexOfObject:value];
        [_segmentedControl addTarget:self action:@selector(segmentedControlTriggered:) forControlEvents:UIControlEventValueChanged];
    }
    
    return self;
}

- (UIControl *)getControl {
    return _segmentedControl;
}

- (void)segmentedControlTriggered:(UIControl *)sender {
    if ([_delegate respondsToSelector:@selector(option:wasSwitchedTo:)]) {
        [_delegate option:_key wasSwitchedTo:[_segmentedControl titleForSegmentAtIndex:_segmentedControl.selectedSegmentIndex]];
    }
}

@end


@implementation OptionsMenu {
    NSArray *_options;
}

- (id)initWithOptions:(NSArray *)options {
    if (self = [super init]) {
        _options = options;
        
        self.preferredContentSize = CGSizeMake(DEFAULT_CELL_WIDTH, DEFAULT_CELL_HEIGHT * [_options count]);
    }
    
    return self;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _options.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger index = [indexPath indexAtPosition:1];
    NSString *cellIdentifier = [NSString stringWithFormat:@"%lu", (unsigned long)index];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        id<OptionsMenuItem> menuItem = [_options objectAtIndex:index];
        UIControl *control = [menuItem getControl];
        
        int x = DEFAULT_CELL_WIDTH - control.frame.size.width;
        int y = (DEFAULT_CELL_HEIGHT - control.frame.size.height) / 2;
        control.frame = CGRectMake(x, y, control.frame.size.width, control.frame.size.height);
        
        [cell addSubview:control];
        cell.textLabel.text = menuItem.key;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

@end
