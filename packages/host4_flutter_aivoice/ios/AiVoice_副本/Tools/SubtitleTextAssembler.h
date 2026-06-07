//
//  SubtitleTextAssembler.h
//  字幕文本拼接器 - 处理 SubtitleMsgData 并返回完整文本
//

#import <Foundation/Foundation.h>
#import "SubtitleMsgData.h"

NS_ASSUME_NONNULL_BEGIN

@interface SubtitleTextAssembler : NSObject

/**
 * 单例
 */
+ (instancetype)sharedAssembler;

/**
 * 处理字幕数据，返回完整文本
 * @param subtitleData SubtitleMsgData 对象
 * @return 当前应该显示的完整文本
 */
- (NSString *)assembleText:(SubtitleMsgData *)subtitleData;

/**
 * 检查消息是否完成
 * @param userId 用户ID
 * @param roundId 轮次ID
 * @return 是否完成
 */
- (BOOL)isCompleteForUser:(NSString *)userId roundId:(NSInteger)roundId;

/**
 * 清空所有缓存
 */
- (void)clearCache;

/**
 * 清空指定用户的缓存
 */
- (void)clearCacheForUser:(NSString *)userId roundId:(NSInteger)roundId;

@end

NS_ASSUME_NONNULL_END
