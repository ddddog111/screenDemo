//
//  SharePath.m
//  screenDemo
//
//  Created by lkk on 2022/3/10.
//

#import "SharePath.h"

@implementation NSDate (Timestamp)
+ (NSString *)timestamp {
    long long timeinterval = (long long)([NSDate timeIntervalSinceReferenceDate] * 1000);
    return [NSString stringWithFormat:@"%lld", timeinterval];
}
@end

@implementation SharePath

/*
    获取文件存储的主路径
*/
+ (NSString *)documentPath {
    static NSString *replaysPath;
    if (!replaysPath) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSURL *documentRootPath = [fileManager containerURLForSecurityApplicationGroupIdentifier:GroupIDKey];
        replaysPath = [documentRootPath.path stringByAppendingPathComponent:@"Replays"];
        if (![fileManager fileExistsAtPath:replaysPath]) {
            NSError *error_createPath = nil;
            BOOL success_createPath = [fileManager createDirectoryAtPath:replaysPath withIntermediateDirectories:true attributes:@{} error:&error_createPath];
            if (success_createPath && !error_createPath) {
                NSLog(@"%@路径创建成功!", replaysPath);
            } else {
                NSLog(@"%@路径创建失败:%@", replaysPath, error_createPath);
            }
        }
    }
    return replaysPath;
}

/*
    获取当前将要录制视频文件的保存路径
*/
+ (NSURL *)filePathUrlWithFileName:(NSString *)fileName{
    NSString *filePath = [fileName stringByAppendingPathExtension:@"mp4"];
    NSString *fullPath = [[self documentPath] stringByAppendingPathComponent:filePath];
    return [NSURL fileURLWithPath:fullPath];
}
 
/*
    用于获取自定义路径下的所有文件
 */
+ (NSArray <NSURL *> *)fetechAllResource {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *documentPath = [self documentPath];
    NSURL *documentURL = [NSURL fileURLWithPath:documentPath];
    NSError *error = nil;
    NSArray<NSURL *> *allResource  =  [fileManager contentsOfDirectoryAtURL:documentURL includingPropertiesForKeys:@[] options:(NSDirectoryEnumerationSkipsSubdirectoryDescendants) error:&error];
    return allResource;
    
}
@end
