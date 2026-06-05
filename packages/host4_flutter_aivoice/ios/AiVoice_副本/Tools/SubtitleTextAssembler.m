//
//  SubtitleTextAssembler.m
//  字幕文本拼接器实现
//

#import "SubtitleTextAssembler.h"

@interface SubtitleTextAssembler ()

// 缓存已确认的文本 [key: "userId-roundId" -> 已确认文本]
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *confirmedTextCache;

// 缓存临时文本 [key: "userId-roundId" -> 临时文本]
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *tempTextCache;

// 完成状态 [key: "userId-roundId" -> BOOL]
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *completeStatusCache;

// ✅ 新增：已处理的消息集合 [key: "userId-roundId" -> Set<消息Hash>]
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSMutableSet<NSString *> *> *processedMessagesCache;

@end

@implementation SubtitleTextAssembler

#pragma mark - Singleton

+ (instancetype)sharedAssembler {
    static SubtitleTextAssembler *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SubtitleTextAssembler alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _confirmedTextCache = [NSMutableDictionary dictionary];
        _tempTextCache = [NSMutableDictionary dictionary];
        _completeStatusCache = [NSMutableDictionary dictionary];
        _processedMessagesCache = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Public Methods

- (NSString *)assembleText:(SubtitleMsgData *)subtitleData {
    if (!subtitleData || !subtitleData.userId) {
        return @"";
    }
    
    // 生成缓存键
    NSString *key = [self makeKey:subtitleData.userId roundId:subtitleData.roundId];
    
    // ✅ 关键修复：检查消息是否已处理
    if ([self isMessageProcessed:subtitleData forKey:key]) {
        // 已处理过，直接返回当前完整文本
        NSString *confirmedText = self.confirmedTextCache[key] ?: @"";
        NSString *tempText = self.tempTextCache[key] ?: @"";
        NSString *completeText = [confirmedText stringByAppendingString:tempText];
        
        NSLog(@"⚠️ [TextAssembler] 消息已处理，跳过: \"%@\"", subtitleData.text);
        
        return completeText;
    }
    
    // ✅ 标记消息为已处理
    [self markMessageAsProcessed:subtitleData forKey:key];
    
    // 获取已确认的文本
    NSString *confirmedText = self.confirmedTextCache[key] ?: @"";
    
    NSString *completeText = @"";
    
    if (subtitleData.definite) {
        // ===== 已确认文本 =====
        
        // 追加到已确认部分
        confirmedText = [confirmedText stringByAppendingString:subtitleData.text];
        
        // 更新缓存
        self.confirmedTextCache[key] = confirmedText;
        
        // 清空临时文本
        [self.tempTextCache removeObjectForKey:key];
        
        // 完整文本就是已确认文本
        completeText = confirmedText;
        
        // 检查是否完成
        if (subtitleData.paragraph) {
            self.completeStatusCache[key] = @(YES);
//            NSLog(@"✅ [TextAssembler] %@-%ld 完成: \"%@\"",
//                  subtitleData.userId, (long)subtitleData.roundId, completeText);
        } else {
//            NSLog(@"✅ [TextAssembler] %@-%ld 已确认: \"%@\"",
//                  subtitleData.userId, (long)subtitleData.roundId, subtitleData.text);
        }
        
    } else {
        // ===== 临时文本 =====
        
        // 保存临时文本
        self.tempTextCache[key] = subtitleData.text;
        
        // 完整文本 = 已确认 + 临时
        completeText = [confirmedText stringByAppendingString:subtitleData.text];
        
//        NSLog(@"🔄 [TextAssembler] %@-%ld 临时: \"%@\"",
//              subtitleData.userId, (long)subtitleData.roundId, subtitleData.text);
    }
    
    // 打印当前完整文本
//    NSLog(@"📄 [TextAssembler] 完整文本: \"%@\"", completeText);
    
    return completeText;
}

- (BOOL)isCompleteForUser:(NSString *)userId roundId:(NSInteger)roundId {
    NSString *key = [self makeKey:userId roundId:roundId];
    NSNumber *status = self.completeStatusCache[key];
    return status ? status.boolValue : NO;
}

- (void)clearCache {
    [self.confirmedTextCache removeAllObjects];
    [self.tempTextCache removeAllObjects];
    [self.completeStatusCache removeAllObjects];
    [self.processedMessagesCache removeAllObjects];
//    NSLog(@"🗑️ [TextAssembler] 已清空所有缓存");
}

- (void)clearCacheForUser:(NSString *)userId roundId:(NSInteger)roundId {
    NSString *key = [self makeKey:userId roundId:roundId];
    [self.confirmedTextCache removeObjectForKey:key];
    [self.tempTextCache removeObjectForKey:key];
    [self.completeStatusCache removeObjectForKey:key];
    [self.processedMessagesCache removeObjectForKey:key];
//    NSLog(@"🗑️ [TextAssembler] 已清空 %@ 的缓存", key);
}

#pragma mark - Private Methods

- (NSString *)makeKey:(NSString *)userId roundId:(NSInteger)roundId {
    return [NSString stringWithFormat:@"%@-%ld", userId, (long)roundId];
}

#pragma mark - Message Deduplication

// ✅ 新增：检查消息是否已处理
- (BOOL)isMessageProcessed:(SubtitleMsgData *)subtitleData forKey:(NSString *)key {
    // 生成消息唯一标识
    NSString *messageHash = [self generateMessageHash:subtitleData];
    
    // 获取或创建已处理消息集合
    NSMutableSet *processedSet = self.processedMessagesCache[key];
    if (!processedSet) {
        processedSet = [NSMutableSet set];
        self.processedMessagesCache[key] = processedSet;
    }
    
    // 检查是否已处理
    return [processedSet containsObject:messageHash];
}

// ✅ 新增：标记消息为已处理
- (void)markMessageAsProcessed:(SubtitleMsgData *)subtitleData forKey:(NSString *)key {
    NSString *messageHash = [self generateMessageHash:subtitleData];
    
    NSMutableSet *processedSet = self.processedMessagesCache[key];
    if (!processedSet) {
        processedSet = [NSMutableSet set];
        self.processedMessagesCache[key] = processedSet;
    }
    
    [processedSet addObject:messageHash];
}

// ✅ 新增：生成消息唯一标识
- (NSString *)generateMessageHash:(SubtitleMsgData *)subtitleData {
    // 基于内容 + 状态生成 hash
    NSString *hashString = [NSString stringWithFormat:@"%@_%d_%d",
                           subtitleData.text ?: @"",
                           subtitleData.definite,
                           subtitleData.paragraph];
    
    return @(hashString.hash).stringValue;
}

@end
