//
//  AppDelegate.m
//  btcker
//
//  Created by Rafael Coelho G. de Oliveira on 2/4/15.
//  Copyright (c) 2015 rafaelcgo. All rights reserved.
//

#import "AppDelegate.h"

#define urlBitstamp  @"https://www.bitstamp.net/api/ticker/"
#define urlFoxbit    @"https://www.bitstamp.net/api/ticker/"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSMenu *statusMenu;
@end

@implementation AppDelegate {
    NSTimer* _getDataTimer;
    NSMutableDictionary* exchanges;
}

@synthesize statusBar = _statusBar;

- (void) awakeFromNib {
    self.statusBar = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    
    self.statusBar.title = @"BTCker";
    self.statusBar.menu = self.statusMenu;
    self.statusBar.highlightMode = YES;

    // you can also set an image
    //self.statusBar.image =
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    exchanges = [NSMutableDictionary dictionaryWithObjects:@[@"0.00", @"0.00"] forKeys:@[@"bitstamp", @"foxbit"]];
    [self setTimer];
    [self getDataFromExchanges];

}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-(void) getDataFromExchanges {
    NSLog(@"getDataFromExchanges");
    [self getDataFromExchange:urlBitstamp];
    [self getDataFromExchange:urlFoxbit];
    [self updateMenuTitle];
}

-(void) getDataFromExchange:(NSString *)exchangeUrl {
    NSLog(@"getDataFromExchange: %@", exchangeUrl);
    NSURL* URL = [NSURL URLWithString:exchangeUrl];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* data = [NSData dataWithContentsOfURL:URL];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateMenuValues:data];
        });
    });
}

- (void) updateMenuValues:(NSData *)data {
    NSLog(@"updateMenuValues");
    if (data == nil) return;
    
    NSError* error = nil;
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"JSON Response: %@",jsonString);
    
    NSDictionary *keyToValue = @{@"volume" : @1,
                                 @"high" : @2,
                                 @"last" : @3,
                                 @"ask" : @4,
                                 @"bid" : @5,
                                 @"vwap" : @6,
                                 @"low" : @7,
                                 @"timestamp" : @8};
    
    [json enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSLog(@"%@ %@", key, obj);
        NSString* value;
        NSString* label = [[key substringToIndex: MIN(4, [key length])] capitalizedString];
        
        // Format the date if the key is the Timestamp
        if ([key isEqualToString: @"timestamp"]) {
            NSDate *date = [NSDate dateWithTimeIntervalSince1970:[obj doubleValue]];
            NSDateFormatter *formatter = [NSDateFormatter new];
            [formatter setDateFormat:@"hh:mm:ss"];
            value = [formatter stringFromDate:date];
        }
        else {
            value = [NSString stringWithFormat:@"%.2f", [obj floatValue]];
        }
        
        // Set the new Label: Value @ the menu item of the _statusMenu
        [[_statusMenu itemAtIndex:[[keyToValue valueForKey:key] integerValue]] setTitle:[NSString stringWithFormat:@"%@: \t%@", label, value]];
    }];

    [exchanges setValue:json[@"last"] forKey:@"bitstamp"];
}

- (void) updateMenuTitle {
    NSLog(@"updateMenuTitle");
    NSString* lastPrice = [exchanges objectForKey:@"bitstamp"];
    NSLog(@"updateMenuTitle: %@", lastPrice);
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSFont systemFontOfSize: 11.0], NSFontAttributeName, nil];
    NSMutableAttributedString* s = [[NSMutableAttributedString alloc]
                                    initWithString:[NSString stringWithFormat:@"%@: %@ | %@: %@", @"Bitstamp", lastPrice, @"Foxbit", lastPrice]
                                    attributes:attributes];
    [_statusBar setAttributedTitle:s];
}

// Timer that calls the getDataFromExchanges
- (void) setTimer {
    double interval = 10.0;
    NSLog(@"setTimer: %f", interval);
    [_getDataTimer invalidate];
    _getDataTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                    target:self
                                                   selector:@selector(getDataFromExchanges)
                                                  userInfo:nil
                                                   repeats:YES];
}

@end
