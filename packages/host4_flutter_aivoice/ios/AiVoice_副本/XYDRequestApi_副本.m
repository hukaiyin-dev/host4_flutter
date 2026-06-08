//
//  XYDRequestApi.m
//  CuteVedio
//
//  Created by jingpan on 2018/7/24.
//  Copyright © 2018年 jingpan. All rights reserved.
//

#import "XYDRequestApi.h"

///基础
///开发
//NSString *const GameMacroBaseUrl = @"https://dev.gamemacro.cn";

///测试
NSString *const GameMacroBaseUrl = @"https://test.gamemacro.cn";

///正式
//NSString *const GameMacroBaseUrl = @"https://gamemacro.cn";


///AI
///AI语音测试环境
//NSString *const AgentChatBaseURL = @"https://test.gamemacro.cn/ai";

///AI语音正式环境
NSString *const AgentChatBaseURL = @"https://gamemacro.cn/ai";

NSString *const BaseCurrentLanguage = @"Accept-Language";

NSString *const BaseCurrentPlatform = @"platform";

NSString *const BaseOrgID = @"accorgid";

NSString *const BaseAccessToken = @"access_token";

NSString *const BaseToken = @"token";

NSString *const BaseContentType = @"Content-Type";

NSString *const BaseUserPosition = @"User-Position";

NSString *const BaseUserIP = @"User-Ip";

NSString *const MachenikeQuestionList = @"question/app/question/list";

NSString *const GMAppConnectQuestion = @"question/app/question/connect";

NSString *const MachenikeAppointQuestion = @"question/app/question";

NSString *const LatestFirmwareVersion = @"user/firmware/last";

NSString *const BeforeFirmwareVersion = @"user/firmware/before";

NSString *const UserDictionaries = @"user/organ/dictionaries";

NSString *const GoodsList = @"goods/list";

NSString *const GoodsCarousel = @"goods/app/goods/carousel";

NSString *const AppList = @"produce/list";

NSString *const AppSearchList = @"produce/app/produce/search";

NSString *const AppUpPhoto = @"external/put/oss";

NSString *const AppUpMarcoConfig = @"game/app/configuration/macro/save";

NSString *const AppShareMarcoConfig = @"game/app/configuration/add";

NSString *const AppTopGameList = @"game/app/configuration/macro/default/list";

NSString *const AppMacroDownload = @"game/app/configuration/macro/download";

NSString *const JSMacroDownload = @"game/app/configuration/download";

NSString *const AppMacroDownloadShareCode = @"game/app/configuration/macro/download/shareCode";

//获取验证码
NSString *const GMUserGetCode = @"user/consumer/register/code";

//校验验证码
NSString *const GMUserCheckCode = @"user/check/code";

//注册
NSString *const GMUserRegist = @"user/consumer/register";

//YH信息
NSString *const GMUserDetail = @"user/detail";

//帖子、评论、点赞、收藏统计
NSString *const GMPostStatistics = @"community/app/statistics/info";

//用户登录
NSString *const GMUserLogin = @"user/login/app";

//用户退出登录
NSString *const GMUserLogout = @"user/logout";

//用户注销
NSString *const GMUserSingOut = @"user/cancel";

//用户更新信息
NSString *const GMUserUpdateInfo = @"user/consumer/update/info";

//绑定获取手机/邮箱验证码
NSString *const GMUserBindCode = @"user/consumer/bind/code";

//绑定手机或邮箱
NSString *const GMUserBindInfo = @"user/consumer/bind/info";

//解绑手机号、邮箱
NSString *const GMUserUnBind = @"user/consumer/unbind";

//原密码修改密码
NSString *const GMUserUpdatePassword = @"user/consumer/update/password";

//忘记密码获取手机/邮箱验证码
NSString *const GMUserForgotCode = @"user/consumer/forgot/code";

//忘记密码修改用户密码
NSString *const GMUserForgot = @"user/consumer/forgot";

//添加反馈
NSString *const GMUserFeedback = @"community/feedback";

//App版本
NSString *const GMAppVersion = @"user/version/last";

//App主题
NSString *const GMUserGetTheme = @"user/theme/app/getTheme";

//游戏模糊搜索
NSString *const GMGameVague = @"game/app/game/vague";

//游戏搜索列表
NSString *const GMGameSearch = @"game/app/game/search";

//APP游戏首页列表
NSString *const GMGameList =  @"game/app/game/list";

//查询所有游戏分类列表
NSString *const GMGameType =  @"game/app/type/list";

//查询指定类型游戏列表
NSString *const GMGameTypeList =  @"game/app/game/type";

//查询指定游戏详情
NSString *const GMGameDetail =  @"game/app/detail";

//查询所有问题分类列表
NSString *const GMQuestionTypeList =  @"question/app/type/list";

//查询资讯列表
NSString *const GMLatestNews = @"community/app/post/latest/news";

//APP游戏首页列表
NSString *const GMGameAppList = @"game/app/list";

//查询主机平台列表
NSString *const GMHostAppList = @"game/host/app/list";

//查询指定主机平台
NSString *const GMHostAppDetail = @"game/host/app/detail";

//查询云游戏平台列表
NSString *const GMPlatformList = @"game/platform/app/list";

//查询云游戏列表
NSString *const GMCloudGameList = @"game/cloud/app/list";

//查询指定云游戏平台
NSString *const GMPlatformDetail = @"game/platform/app/detail";

//查询指定名称产品
NSString *const ProduceAppDetail = @"produce/app/detail";

//查询指定产品全部配置
NSString *const ProduceAppConfig = @"produce/app/config";

//查询产品搜索关键词
NSString *const ProduceAppKeyword = @"produce/app/keyword/list";

//查询灯光位置信息
NSString *const DevLightDetail = @"produce/app/light/detail";

//设备产品信息
NSString *const AppPruductList = @"produce/app/match/list";




#pragma mark - AI智能体

///智能体入房
NSString *const startVoiceChat = @"start_voice_chat";

///智能体退房
NSString *const stopVoiceChat = @"stop_voice_chat";

///智能体更新
NSString *const updateVoiceChat = @"update_voice_chat";

///用户会员使用
NSString *const aiExpiredUserUse = @"goods/aiUserExpired/userUse";

///用户游戏时长记录
NSString *const aiExpiredAddGameTime = @"goods/aiUserExpired/addGameTime";

///AI下单支付
NSString *const aiOrderPay = @"goods/aiOrder/createPayOrder";

///苹果支付回调
NSString *const aiAppleStorePayNotify = @"goods/aiOrder/app/appleStorePayNotify";
