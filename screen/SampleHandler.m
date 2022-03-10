//
//  SampleHandler.m
//  screen
//
//  Created by lkk on 2022/3/10.
//

#import "SampleHandler.h"
#import "SharePath.h"

@interface SampleHandler()

//使用以下保存mp4
@property (strong, nonatomic) AVAssetWriter *assetWriter;
@property (strong, nonatomic) AVAssetWriterInput *videoInput;
@property (strong, nonatomic) AVAssetWriterInput *audioAppInput;
@property (strong, nonatomic) AVAssetWriterInput *audioMicInput;

@end

@implementation SampleHandler

- (void)setupAssetWriter {
    if ([self.assetWriter canAddInput:self.videoInput]) {
        [self.assetWriter addInput:self.videoInput];
    } else {
        NSAssert(false, @"添加视频写入失败");
    }
    if ([self.assetWriter canAddInput:self.audioAppInput]) {
        [self.assetWriter addInput:self.audioAppInput];
    } else {
        NSAssert(false, @"添加App音频写入失败");
    }
    if ([self.assetWriter canAddInput:self.audioMicInput]) {
        [self.assetWriter addInput:self.audioMicInput];
    } else {
        NSAssert(false, @"添加Mic音频写入失败");
    }
}

- (AVAssetWriter *)assetWriter {
    if (!_assetWriter) {
        NSError *error = nil;
        NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:GroupIDKey];
        NSString *fileName = [sharedDefaults objectForKey:FileKey];
        NSURL *filePathURL = [SharePath filePathUrlWithFileName:fileName];//保存在共享文件夹中
        _assetWriter = [[AVAssetWriter alloc] initWithURL:filePathURL fileType:(AVFileTypeMPEG4) error:&error];
        NSAssert(!error, @"_assetWriter初始化失败");
    }
    return _assetWriter;
}

- (AVAssetWriterInput *)videoInput {
    if (!_videoInput) {
        CGSize size = [UIScreen mainScreen].bounds.size;
        //写入视频大小
        NSInteger numPixels = size.width  * size.height;
        //每像素比特
        CGFloat bitsPerPixel = 10;
        NSInteger bitsPerSecond = numPixels * bitsPerPixel;
        // 码率和帧率设置
        NSDictionary *compressionProperties = @{
            AVVideoAverageBitRateKey : @(bitsPerSecond),//码率(平均每秒的比特率)
            AVVideoExpectedSourceFrameRateKey : @(15),//帧率（如果使用了AVVideoProfileLevelKey则该值应该被设置，否则可能会丢弃帧以满足比特流的要求）
            AVVideoMaxKeyFrameIntervalKey : @(15),//关键帧最大间隔
            AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel,
        };
        
        NSDictionary *videoOutputSettings = @{
            AVVideoCodecKey : AVVideoCodecTypeH264,
            AVVideoScalingModeKey : AVVideoScalingModeResizeAspect,
            AVVideoWidthKey : @(size.width * 2),
            AVVideoHeightKey : @(size.height * 2),
            AVVideoCompressionPropertiesKey : compressionProperties
        };
        _videoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoOutputSettings];
        _videoInput.expectsMediaDataInRealTime = true;//实时录制

    }
    return _videoInput;
}

- (AVAssetWriterInput *)audioAppInput {
    if (!_audioAppInput) {
        NSDictionary *audioCompressionSettings = @{ AVEncoderBitRatePerChannelKey : @(28000),
                                                    AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                                    AVNumberOfChannelsKey : @(1),
                                                    AVSampleRateKey : @(22050) };

        _audioAppInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
        _audioAppInput.expectsMediaDataInRealTime = true;//实时录制
    }
    return _audioAppInput;
}
- (AVAssetWriterInput *)audioMicInput {
    if (!_audioMicInput) {
        NSDictionary *audioCompressionSettings = @{ AVEncoderBitRatePerChannelKey : @(28000),
                                                    AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                                    AVNumberOfChannelsKey : @(1),
                                                    AVSampleRateKey : @(22050) };

        _audioMicInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
        _audioMicInput.expectsMediaDataInRealTime = true;//实时录制
    }
    return _audioMicInput;
}

- (void)broadcastStartedWithSetupInfo:(NSDictionary<NSString *,NSObject *> *)setupInfo {
    // User has requested to start the broadcast. Setup info from the UI extension can be supplied but optional.
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge CFStringRef)ScreenDidStartNotif,NULL,nil,YES);
    [self setupAssetWriter];//初始化AssetWriter
    NSLog(@"开始录屏");
}

- (void)broadcastPaused {
    // User has requested to pause the broadcast. Samples will stop being delivered.
    NSLog(@"录屏暂停");
}

- (void)broadcastResumed {
    // User has requested to resume the broadcast. Samples delivery will resume.
    NSLog(@"录屏继续");
}
- (void)finishBroadcastWithError:(NSError *)error {
    NSLog(@"录屏错误");
    [self stopWriting];
    [super finishBroadcastWithError:error];
    //通知主程 录屏结束
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge CFStringRef)ScreenDidFinishNotif,NULL,nil,YES);
}
- (void)broadcastFinished {
    // User has requested to finish the broadcast.
    NSLog(@"录屏结束");
    [self stopWriting];
    //通知主程 录屏结束
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),(__bridge CFStringRef)ScreenDidFinishNotif,NULL,nil,YES);
}

- (void)processSampleBuffer:(CMSampleBufferRef)sampleBuffer withType:(RPSampleBufferType)sampleBufferType {
    
    switch (sampleBufferType) {
        case RPSampleBufferTypeVideo:
            // Handle video sample buffer
            @autoreleasepool {
                AVAssetWriterStatus status = self.assetWriter.status;
                if ( status == AVAssetWriterStatusFailed || status == AVAssetWriterStatusCompleted || status == AVAssetWriterStatusCancelled) {
                    NSAssert(false,@"屏幕录制AVAssetWriterStatusFailed error :%@", self.assetWriter.error);
                    return;
                }
                if (status == AVAssetWriterStatusUnknown) {
                    [self.assetWriter startWriting];
                    CMTime time = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
                    [self.assetWriter startSessionAtSourceTime:time];
                }
                if (status == AVAssetWriterStatusWriting) {
                    if (self.videoInput.isReadyForMoreMediaData) {
                       BOOL success = [self.videoInput appendSampleBuffer:sampleBuffer];
                        if (!success) {
                            [self stopWriting];
                        }
                    }
                }
            }
            break;
        case RPSampleBufferTypeAudioApp:
            if (self.audioAppInput.isReadyForMoreMediaData) {
                BOOL success = [self.audioAppInput appendSampleBuffer:sampleBuffer];
                if (!success) {
                    [self stopWriting];
                }
            }
            // Handle audio sample buffer for app audio
            break;
        case RPSampleBufferTypeAudioMic:
            if (self.audioMicInput.isReadyForMoreMediaData) {
                BOOL success = [self.audioMicInput appendSampleBuffer:sampleBuffer];
                if (!success) {
                    [self stopWriting];
                }
            }
            // Handle audio sample buffer for mic audio
            break;
        default:
            break;
    }
}

- (void)stopWriting{
    if (self.assetWriter.status == AVAssetWriterStatusWriting) {
        [self.videoInput markAsFinished];
        [self.audioAppInput markAsFinished];
        [self.audioMicInput markAsFinished];
        if(@available(iOS 14.0, *)){
            [self.assetWriter finishWritingWithCompletionHandler:^{
                self.videoInput = nil;
                self.audioAppInput = nil;
                self.audioMicInput = nil;
                self.assetWriter = nil;
            }];
        }else{//iOS14之前使用弃用方法mp4才能播放
            [self.assetWriter finishWriting];
        }
    }
}
@end
