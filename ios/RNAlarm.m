#import "RNAlarm.h"
#if __has_include("RCTUtils.h")
#import "RCTUtils.h"
#else
#import <React/RCTUtils.h>
#endif

#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

@implementation RNAlarm
//AVAudioPlayer *audioPlay;

-(void) setAlarm: (NSString *) triggerTime andStatus: (NSString * ) status{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    [userDefault setObject:status forKey:triggerTime];
    [userDefault synchronize];
}


-(int) getAlarmStatus: (NSString *) triggerTime{
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSString *strStatus = [userDefault objectForKey:triggerTime];
    
    if (strStatus == nil) {
        return -1;
    }else{
        return [strStatus isEqualToString:@"error"] ? NO : YES;
    }
}

-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler{
    
     completionHandler(UNNotificationPresentationOptionAlert | UNNotificationPresentationOptionSound);
 
    AudioServicesPlayAlertSoundWithCompletion(kSystemSoundID_Vibrate, nil);
}

-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler{
    // if(response.actionIdentifier == @"clear.repeat.action") {
    
    NSString *categoryIdentifier = response.notification.request.content.categoryIdentifier;
    NSString *identifier1 = [categoryIdentifier stringByAppendingString:@"1"];
    NSString *identifier2 = [categoryIdentifier stringByAppendingString:@"2"];
    NSString *identifier3 = [categoryIdentifier stringByAppendingString:@"3"];
    
    [center removePendingNotificationRequestsWithIdentifiers:@[identifier1,identifier2,identifier3]];
    [center removeDeliveredNotificationsWithIdentifiers:@[identifier1,identifier2,identifier3]];
    //[audioPlay stop];
    //[center removeAllPendingNotificationRequests];
    //}
    
    completionHandler();
}
//-(void)playSound() {
////    NSString *soundFilePath = [NSString stringWithFormat:@"%@/Constellation.m4r", [[NSBundle mainBundle] resourcePath]];
////    NSURL *fileURL =[[NSURL alloc] initFileURLWithPath:soundFilePath];
//    NSURL *from = [NSURL fileURLWithPath:@"/Library/Ringtones/Constellation.m4r"];
//    AVAudioPlayer *audioPlay = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:nil];
//    audioPlay.numberOfLoops = -1;
//    [audioPlay play];
//}
- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE();

// Thanks, AshFurrow
static const unsigned componentFlags = (NSCalendarUnitYear| NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitWeekday |  NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond | NSCalendarUnitWeekday | NSCalendarUnitWeekdayOrdinal);

RCT_EXPORT_METHOD(playTipSound: (NSString*)fileName){
    
    NSString *soundPath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"m4r"];
    SystemSoundID soundID = 0;
    NSURL *url = [NSURL fileURLWithPath:soundPath];
    AudioServicesCreateSystemSoundID(CFBridgingRetain(url), &soundID);
    AudioServicesPlaySystemSound (soundID);
}

RCT_EXPORT_METHOD(clearAlarm){
    NSUserDefaults *userDefault = [NSUserDefaults standardUserDefaults];
    NSDictionary *dic = [userDefault dictionaryRepresentation];
    for (id key in dic) {
        [userDefault removeObjectForKey:key];
    }
    [userDefault synchronize];
}



RCT_EXPORT_METHOD(initAlarm: successCallback:(RCTResponseSenderBlock)callback){
    
    UNUserNotificationCenter *rCenter = UNUserNotificationCenter.currentNotificationCenter;
    [rCenter requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound)
                           completionHandler:^(BOOL granted, NSError * _Nullable error){
                               // Enable or disable based on authorization
                               if (granted == YES) {
                                   NSArray *result = [NSArray arrayWithObjects:[NSNumber numberWithBool:NO], nil];
                                   if(successCallback != nil){
                                       result = [NSArray arrayWithObjects:[NSNumber numberWithBool:YES], nil];
                                   }
                                   callback(result);
                               }
                           }];
}

RCT_EXPORT_METHOD(setAlarm:(NSString *)triggerTime
                  title:(NSString *)title
                  successCallback:(RCTResponseSenderBlock)successCallback
                  errorCallback:(RCTResponseSenderBlock)errorCallback){
    @try
    {
        int alarmStatus = [self getAlarmStatus:triggerTime];
        
        bool isSettedAlarm = [NSNumber numberWithInt:alarmStatus].boolValue;
        if (alarmStatus != -1)
        {
            if (isSettedAlarm) {
                NSArray *result = [NSArray arrayWithObjects:@"0", nil];
                if(successCallback != nil){
                    successCallback(result);
                    return;
                }
            }
            else
            {
                NSArray *result = [NSArray arrayWithObjects:@"0",nil];
                if(errorCallback != nil) {
                    errorCallback(result);
                    return;
                }
            }
        }
        
        UNUserNotificationCenter *rCenter = UNUserNotificationCenter.currentNotificationCenter;
        [rCenter requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound)
                               completionHandler:^(BOOL granted, NSError * _Nullable error){
                                   // Enable or disable based on authorization
                               }];

        
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        //content.title = [NSString localizedUserNotificationStringForKey:@"RNALarm" arguments:nil];
        content.body = [NSString localizedUserNotificationStringForKey:title arguments:nil];
        //content.categoryIdentifier = @"RNAlarmCategory";
        content.categoryIdentifier = triggerTime;
        content.sound = [UNNotificationSound defaultSound];
        
        // current date
        NSDate *date = [NSDate date];
        double nowSeconds = [date timeIntervalSince1970];
        
        double startDate =[triggerTime doubleValue];
        
        double intervalSeconds = startDate/1000 - nowSeconds;
        //NSTimeInterval time =[triggerTime doubleValue];
        if (intervalSeconds > 0) {
            
            //for (int i=0;  i<3; i++) {
            UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:intervalSeconds repeats:NO];
            UNTimeIntervalNotificationTrigger *trigger1 = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval: intervalSeconds + 60 repeats:NO];
            UNTimeIntervalNotificationTrigger *trigger2 = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval: intervalSeconds + 120 repeats:NO];
            
            
            
            UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier: [triggerTime stringByAppendingString: @"1"] content:content trigger:trigger];
            UNNotificationRequest *request1 = [UNNotificationRequest requestWithIdentifier:[triggerTime stringByAppendingString: @"2"] content:content trigger:trigger1];
            UNNotificationRequest *request2 = [UNNotificationRequest requestWithIdentifier:[triggerTime stringByAppendingString: @"3"] content:content trigger:trigger2];
            
            
            
            UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
            
            //NSArray *actionOption = [NSArray arrayWithObject:@"actionOption"];
            
            UNNotificationAction *action = [UNNotificationAction
                                            actionWithIdentifier:@"clear.repeat.action"
                                            title:@""
                                            options:UNNotificationActionOptionForeground];
            UNNotificationCategory *category = [UNNotificationCategory
                                                //categoryWithIdentifier:@"RNAlarmCategory"
                                                categoryWithIdentifier:triggerTime
                                                actions:@[action]
                                                intentIdentifiers:@[]
                                                options:UNNotificationCategoryOptionCustomDismissAction];
            
            [center setNotificationCategories: [NSSet setWithObjects:category, nil]];
            [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
                if(error != nil)
                {
                    // NSLog(error.localizedDescription);
                    @throw error;
                }
            }];
            [center addNotificationRequest:request1 withCompletionHandler:^(NSError * _Nullable error) {
                if(error != nil)
                {
                    // NSLog(error.localizedDescription);
                    @throw error;
                }
            }];
            [center addNotificationRequest:request2 withCompletionHandler:^(NSError * _Nullable error) {
                if(error != nil)
                {
                    // NSLog(error.localizedDescription);
                    @throw error;
                }
            }];
            
            center.delegate = self;
            //intervalSeconds += 60;
            //}
            [self setAlarm:triggerTime andStatus:@"success"];
            
            NSArray *result = [NSArray arrayWithObjects:@"0", nil];
            if(successCallback != nil){
                successCallback(result);
            }
        }
        else{
            [self setAlarm:triggerTime andStatus:@"error"];
            
            NSArray *result = [NSArray arrayWithObjects:@"0",nil];
            if(errorCallback != nil) {
                errorCallback(result);
            }
        }
        
        
        
    }
    @catch(NSException *exception){
        NSLog(@"%@", exception.reason);
        NSArray *result = [NSArray arrayWithObjects:@"1",exception.reason, nil];
        if(errorCallback != nil) {
            errorCallback(result);
        }
    }
}



RCT_EXPORT_METHOD(setAlarmWithPromise:(NSString *)triggerTime
                  title:(NSString *)title
                  musicUri:(nullable NSString *)musicUri
                  resolver:(RCTPromiseResolveBlock)resolver
                  reject:(RCTPromiseRejectBlock)reject){
    @try
    {
        UNUserNotificationCenter *rCenter = UNUserNotificationCenter.currentNotificationCenter;
        [rCenter requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionSound)
                               completionHandler:^(BOOL granted, NSError * _Nullable error){
                                   // Enable or disable based on authorization
                               }];
        
        UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
        //content.title = [NSString localizedUserNotificationStringForKey:@"RNALarm" arguments:nil];
        content.body = [NSString localizedUserNotificationStringForKey:title arguments:nil];
        if(musicUri == nil) {
            content.sound = [UNNotificationSound defaultSound];
        }else {
            content.sound = [UNNotificationSound soundNamed:musicUri];
        }
        NSTimeInterval time =[triggerTime doubleValue];
        NSDate *tgTime = [NSDate dateWithTimeIntervalSince1970:time];
        NSDateComponents *components = [[NSCalendar autoupdatingCurrentCalendar] components:componentFlags fromDate:tgTime];
        UNCalendarNotificationTrigger *trigger = [UNCalendarNotificationTrigger triggerWithDateMatchingComponents:components repeats:NO];
        
        UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:@"RNAlarm" content:content trigger:trigger];
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
            if(error != nil)
            {
                // NSLog(error.localizedDescription);
                @throw error;
            }
        }];
        
        NSArray *result = [NSArray arrayWithObjects:@"0", nil];
        resolver(result);
    }
    @catch(NSException *exception){
        NSLog(@"%@", exception.reason);
        NSError *error = [[NSError alloc] init];
        
        reject(@"RNAlarm_Errror", exception.name, error);
    }
}

@end


