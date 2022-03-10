//
//  ViewController.m
//  screenDemo
//
//  Created by lkk on 2022/3/10.
//


#import "ViewController.h"
#import <ReplayKit/ReplayKit.h>
#import "SharePath.h"
#import <AVKit/AVKit.h>
#import <Photos/Photos.h>

static void onDarwinReplayKit2PushFinish(CFNotificationCenterRef center,
                                        void *observer, CFStringRef name,
                                        const void *object, CFDictionaryRef
                                        userInfo){
    //转到cocoa层框架处理
    [[NSNotificationCenter defaultCenter] postNotificationName:ScreenRecordFinishNotif object:nil];
}
static void onDarwinReplayKit2PushStart(CFNotificationCenterRef center,
                                        void *observer, CFStringRef name,
                                        const void *object, CFDictionaryRef
                                        userInfo){
    //转到cocoa层框架处理
    [[NSNotificationCenter defaultCenter] postNotificationName:ScreenRecordStartNotif object:nil];
}


@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.title = @"录屏demo";
    
    RPSystemBroadcastPickerView *pickView = [[RPSystemBroadcastPickerView alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    [self.view addSubview:pickView];
    pickView.preferredExtension = ScreenExtension;
    pickView.center = self.view.center;
    
    UILabel *alertLab = [[UILabel alloc]initWithFrame:CGRectMake(0, pickView.center.y+30,  [UIScreen mainScreen].bounds.size.width, 40)];
    alertLab.textAlignment = NSTextAlignmentCenter;
    alertLab.text = @"点击上面开始录屏";
    [self.view addSubview:alertLab];
    
    //注册录屏开始与完成通知
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)(self),
                                    onDarwinReplayKit2PushStart,
                                    (__bridge CFStringRef)(ScreenDidStartNotif),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    (__bridge const void *)(self),
                                    onDarwinReplayKit2PushFinish,
                                    (__bridge CFStringRef)(ScreenDidFinishNotif),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScreenRecordStartNotification:) name:ScreenRecordStartNotif object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleScreenRecordEndNotification:) name:ScreenRecordFinishNotif object:nil];
    
    if(![UIScreen mainScreen].isCaptured){//正在录屏
        NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:GroupIDKey];
        NSString *fileName = [sharedDefaults objectForKey:FileKey];
        if (fileName.length>0) {//录屏时app挂掉重启后也可找到mp4
            NSURL *oldUrl = [SharePath filePathUrlWithFileName:fileName];
            [self moveFromGroupUrl:oldUrl];
        }
    }
    
}

//录屏开始以后的推送
- (void)handleScreenRecordStartNotification:(NSNotification*)noti{
    NSLog(@"录屏开始：%@",noti);
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:GroupIDKey];
    NSString *fileName = [NSDate timestamp];//mp4播放后fileName重新生成
    [sharedDefaults setObject:fileName forKey:FileKey];
    [sharedDefaults synchronize];
}

//录屏结束以后的推送
- (void)handleScreenRecordEndNotification:(NSNotification*)noti{
    NSLog(@"录屏结束：%@",noti);
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:GroupIDKey];
    NSString *fileName = [sharedDefaults objectForKey:FileKey];
    if (fileName.length>0) {
        NSURL *oldUrl = [SharePath filePathUrlWithFileName:fileName];
        [self moveFromGroupUrl:oldUrl];
    }
}

- (void)moveFromGroupUrl:(NSURL *)oldUrl{
    
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSURL *newUrl = [NSURL fileURLWithPath:[path stringByAppendingString:[NSString stringWithFormat:@"/%@.mp4",[NSDate timestamp]]]];
    NSLog(@"oldUrl:%@ \n newUrl:%@",oldUrl,newUrl);
    NSError *error;
    [[NSFileManager defaultManager]moveItemAtURL:oldUrl toURL:newUrl error:&error];
    if (error) {
        NSLog(@"转移失败:%@",error);
        [self playVideo:oldUrl];
    }else{
        NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:GroupIDKey];
        [sharedDefaults removeObjectForKey:FileKey];
        [sharedDefaults synchronize];
        [self playVideo:newUrl];
    }
}

//播放录屏后的mp4
- (void)playVideo:(NSURL *)url{
    
    //播放mp4
    AVPlayerViewController *playerViewController;
    playerViewController = [[AVPlayerViewController alloc] init];
    playerViewController.player = [AVPlayer playerWithURL:url];
    [self presentViewController:playerViewController animated:YES completion:^{
        [playerViewController.player play];
        NSLog(@"error == %@", playerViewController.player.error);
    }];
    
    //保存到相册
//    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
//        [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
//    } completionHandler:^(BOOL success, NSError * _Nullable error) {
//        if (error) {
//            NSLog(@"保存失败：%@",error);
//        }else{
//            NSLog(@"保存成功");
//        }
//    }];
}
@end
