//
//  SharePath.h
//  screenDemo
//
//  Created by lkk on 2022/3/10.
//

#import <Foundation/Foundation.h>


NS_ASSUME_NONNULL_BEGIN
static NSString *ScreenExtension = @"com.lkk.demo.screen";
static NSString *GroupIDKey = @"group.com.lkk.demo";
#warning 以上均需改成自用的id

static NSString *FileKey = @"screen_file_key";

static NSString *ScreenDidStartNotif = @"ScreenDidStart";
static NSString *ScreenDidFinishNotif = @"ScreenDidFinish";
static NSString *ScreenRecordStartNotif = @"ScreenRecordStart";
static NSString *ScreenRecordFinishNotif = @"ScreenRecordFinish";


@interface NSDate (Timestamp)

+ (NSString *)timestamp;

@end

@interface SharePath : NSObject

/*
    获取当前将要录制视频文件的保存路径
*/
+ (NSURL *)filePathUrlWithFileName:(NSString *)fileName;

/*
   用于获取自定义路径下的所有文件
*/
+ (NSArray <NSURL *> *)fetechAllResource;
@end

NS_ASSUME_NONNULL_END
