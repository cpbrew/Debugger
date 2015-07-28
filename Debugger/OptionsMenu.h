//
//  OptionsMenu.h
//  Debugger
//
//  Created by Christopher Brew on 3/6/13.
//
//

@protocol OptionsMenuDelegate <NSObject>

- (void)option:(NSString *)option wasSwitchedTo:(id)value;

@end


@protocol OptionsMenuItem

@property (readonly) NSString *key;

- (UIControl *)getControl;

@end


@interface OptionsMenuBoolItem : NSObject <OptionsMenuItem>

- (id)initWithKey:(NSString *)key initialValue:(BOOL)value delegate:(id<OptionsMenuDelegate>) delegate;

@end


@interface OptionsMenuSliderItem : NSObject <OptionsMenuItem>

- (id)initWithKey:(NSString *)key min:(int)min max:(int)max initialValue:(int)value delegate:(id<OptionsMenuDelegate>) delegate;

@end


@interface OptionsMenuSegmentedItem : NSObject <OptionsMenuItem>

- (id)initWithKey:(NSString *)key items:(NSArray *)items initialValue:(NSString *)value delegate:(id<OptionsMenuDelegate>) delegate;

@end


@interface OptionsMenu : UITableViewController

- (id)initWithOptions:(NSArray *)options;

@end
