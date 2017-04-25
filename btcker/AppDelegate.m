//
//  AppDelegate.m
//  btcker
//
//  Created by Rafael Coelho G. de Oliveira on 2/4/15.
//  Copyright (c) 2015 rafaelcgo. All rights reserved.
//

#import "AppDelegate.h"

#define fontSize  @11.0

// {"high": "222.00",
//  "last": "221.90",
//  "timestamp": "1423618756",
//  "bid": "221.79",
//  "vwap": "218.81",
//  "volume": "7430.56344671",
//  "low": "215.00",
//  "ask": "221.90",
//  "open": "222.00"}
#define urlBitstamp  @"https://www.bitstamp.net/api/ticker/"

// {"high": 669.0,
//  "vol": 98.26505854,
//  "buy": 653.79,
//  "last": 653.79,
//  "low": 637.0,
//  "pair": "BTCBRL",
//  "sell": 656.98,
//  "vol_brl": 63617.11713811}
#define urlFoxbit    @"https://api.blinktrade.com/api/v1/BRL/ticker?crypto_currency=BTC"

// {"BTC_DCR":
//  {"id":162,
//  "last":"0.01347828",
//  "lowestAsk":"0.01345777",
//  "highestBid":"0.01340003",
//  "percentChange":"-0.01818912",
//  "baseVolume":"1104.74075448",
//  "quoteVolume":"81078.19915898",
//  "isFrozen":"0",
//  "high24hr":"0.01437768",
//  "low24hr":"0.01303200"},
// }
#define urlPoloniex  @"https://poloniex.com/public?command=returnTicker"

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
    
    self.statusBar.title = @"BTCker loading...";
    self.statusBar.menu = self.statusMenu;
    self.statusBar.highlightMode = YES;

    // you can also set an image
    //self.statusBar.image =
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    exchanges = [NSMutableDictionary dictionaryWithObjects:@[@"0.00", @"0.00", @"0.00"] forKeys:@[@"bitstamp", @"foxbit", @"poloniex"]];
    [self setTimer];
    [self getDataFromExchanges];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

-(void) getDataFromExchanges {
    NSLog(@"[getDataFromExchanges]");
    [self getDataFromExchange:@"bitstamp" withUrl:urlBitstamp];
    [self getDataFromExchange:@"foxbit" withUrl:urlFoxbit];
    [self getDataFromExchange:@"poloniex" withUrl:urlPoloniex];
}

-(void) getDataFromExchange:(NSString *)exchange withUrl:(NSString *)exchangeUrl {
    NSLog(@"[getDataFromExchange] %@", exchangeUrl);
    NSURL* URL = [NSURL URLWithString:exchangeUrl];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData* data = [NSData dataWithContentsOfURL:URL];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateMenuValues:data forExchange:exchange];
            [self updateMenuTitle];
        });
    });
}

- (void) updateMenuValues:(NSData *)data forExchange:(NSString *)exchange{
    NSLog(@"[updateMenuValues]");
    if (data == nil) return;
    
    NSError* error = nil;
    NSDictionary *keyToValue;
    NSDictionary* json = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
//    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    NSLog(@"[updateMenuValues] JSON Response: %@",jsonString);
    
    if ([exchange  isEqualToString: @"bitstamp"]) {
        keyToValue = @{@"last" : @1,
                       @"high" : @2,
                       @"low" : @3,
                       @"ask" : @4,
                       @"bid" : @5,
                       @"volume" : @6,
                       @"vwap" : @-1,
                       @"timestamp" : @-1,
                       @"open" : @-1};
    }
    else if ([exchange isEqualToString:@"foxbit"]) {
        keyToValue = @{@"last" : @9,
                       @"high" : @10,
                       @"low" : @11,
                       @"sell" : @12,
                       @"buy" : @13,
                       @"vol" : @14,
                       @"pair" : @-1,
                       @"vol_brl" : @-1};
    }
    else if ([exchange isEqualToString:@"poloniex"]) {
        keyToValue = @{@"id" : @-1,
                       @"last" : @17,
                       @"high24hr" : @18,
                       @"low24hr" : @19,
                       @"lowestAsk" : @20,
                       @"highestBid" : @21,
                       @"baseVolume" : @22,
                       @"percentChange" : @-1,
                       @"quoteVolume" : @-1,
                       @"isFrozen" : @-1};
        
        json = [json objectForKey:@"BTC_DCR"];
    }
    


    [json enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        NSLog(@"[updateMenuValues] %@: %@", key, obj);
        NSString* value;
        NSString* label = [[key substringToIndex: MIN(4, [key length])] uppercaseString];
        
//        // Format the date if the key is the Timestamp
//        if ([key isEqualToString: @"timestamp"]) {
//            NSDate *date = [NSDate dateWithTimeIntervalSince1970:[obj doubleValue]];
//            NSDateFormatter *formatter = [NSDateFormatter new];
//            [formatter setDateFormat:@"hh:mm:ss"];
//            value = [formatter stringFromDate:date];
//        }
//        else {
//            value = [NSString stringWithFormat:@"%.2f", [obj floatValue]];
//        }
        value = [NSString stringWithFormat:@"%.8f", [obj floatValue]];
        
        // Set the new Label: Value @ the menu item of the _statusMenu
        NSInteger index = [[keyToValue valueForKey:key] integerValue];
        if (index != -1) {
            [[_statusMenu itemAtIndex:index] setTitle:[NSString stringWithFormat:@"%@: \t%@", label, value]];
        }
    }];

    [exchanges setValue:json[@"last"] forKey:exchange];
}

- (void) updateMenuTitle {
    NSString* lastPriceBitStamp = [exchanges objectForKey:@"bitstamp"];
    NSString* lastPriceFoxBit = [exchanges objectForKey:@"foxbit"];
    NSString* lastPricePoloniex = [exchanges objectForKey:@"poloniex"];
    NSLog(@"[updateMenuTitle] Bitstamp: %@ | Foxbit: %@ | Poloniex: %@", lastPriceBitStamp, lastPriceFoxBit, lastPricePoloniex);
    
    NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:
                                [NSFont systemFontOfSize: [fontSize floatValue]], NSFontAttributeName, nil];
    NSMutableAttributedString* s = [[NSMutableAttributedString alloc]
                                    initWithString:[NSString stringWithFormat:@"%@: %@ | %@: %@ | %@: %@", @"S", lastPriceBitStamp, @"F", lastPriceFoxBit, @"P", lastPricePoloniex]
                                    attributes:attributes];
    [_statusBar setAttributedTitle:s];
}

// Timer that calls the getDataFromExchanges
- (void) setTimer {
    double interval = 10.0;
    NSLog(@"[setTimer] %f", interval);
    [_getDataTimer invalidate];
    _getDataTimer = [NSTimer scheduledTimerWithTimeInterval:interval
                                                    target:self
                                                   selector:@selector(getDataFromExchanges)
                                                  userInfo:nil
                                                   repeats:YES];
}

@end
