//
//  XYDRequestApi.h
//  CuteVedio
//
//  Created by 敬攀 on 2018/7/24.
//  Copyright © 2018年 ;. All rights reserved.
//

#import <Foundation/Foundation.h>

//地址前缀
extern NSString *const GameMacroBaseUrl;

//各种域名
extern NSString *const UserDictionaries;

//当前语言
extern NSString *const BaseCurrentLanguage;

//当前系统
extern NSString *const BaseCurrentPlatform;

//组织id
extern NSString *const BaseOrgID;

//BaseAccessToken
extern NSString *const BaseAccessToken;

//token
extern NSString *const BaseToken;

//ContentType
extern NSString *const BaseContentType;

//经纬度
extern NSString *const BaseUserPosition;

//公网IP
extern NSString *const BaseUserIP;

//问题列表
extern NSString *const MachenikeQuestionList;

//查询指定设备连接问题
extern NSString *const GMAppConnectQuestion;

//指定设备问题
extern NSString *const MachenikeAppointQuestion;

//固件最新版本
extern NSString *const LatestFirmwareVersion;

//固件历史版本
extern NSString *const BeforeFirmwareVersion;

//产品列表
extern NSString *const GoodsList;

//轮播
extern NSString *const GoodsCarousel;

//产品分页列表
extern NSString *const AppList;

//搜索产品
extern NSString *const AppSearchList;

//上传图片
extern NSString *const AppUpPhoto;

//上传宏配置
extern NSString *const AppUpMarcoConfig;

//分享宏配置
extern NSString *const AppShareMarcoConfig;

//下载分享宏配置
extern NSString *const AppMacroDownloadShareCode;

//下载JS宏配置
extern NSString *const JSMacroDownload;

//查询宏配置
extern NSString *const AppMacroDownload;

//推荐配置列表
extern NSString *const AppTopGameList;

//获取验证码
extern NSString *const GMUserGetCode;

//校验验证码
extern NSString *const GMUserCheckCode;

//用户注册
extern NSString *const GMUserRegist;

//用户注销
extern NSString *const GMUserSingOut;

//YH信息
extern NSString *const GMUserDetail;

//统计
extern NSString *const GMPostStatistics;

//用户登录
extern NSString *const GMUserLogin;

//用户退出登录
extern NSString *const GMUserLogout;

//用户更新信息
extern NSString *const GMUserUpdateInfo;

//绑定获取手机/邮箱验证码
extern NSString *const GMUserBindCode;

//绑定手机或邮箱
extern NSString *const GMUserBindInfo;

//解绑手机号、邮箱
extern NSString *const GMUserUnBind;

//原密码修改密码
extern NSString *const GMUserUpdatePassword;

//忘记密码获取手机/邮箱验证码
extern NSString *const GMUserForgotCode;

//忘记密码修改用户密码
extern NSString *const GMUserForgot;

//添加反馈
extern NSString *const GMUserFeedback;

//App版本
extern NSString *const GMAppVersion;

//App主题
extern NSString *const GMUserGetTheme;

//游戏模糊搜索
extern NSString *const GMGameVague;

//游戏搜索列表
extern NSString *const GMGameSearch;

//APP游戏首页列表
extern NSString *const GMGameList;

//查询所有游戏分类列表
extern NSString *const GMGameType;

//查询指定类型游戏列表
extern NSString *const GMGameTypeList;

//查询指定游戏详情
extern NSString *const GMGameDetail;

//查询所有问题分类列表
extern NSString *const GMQuestionTypeList;

//查询资讯列表
extern NSString *const GMLatestNews;

//查询主机平台列表
extern NSString *const GMHostAppList;

//查询指定主机平台
extern NSString *const GMHostAppDetail;

//查询云游戏平台列表
extern NSString *const GMPlatformList;

//查询云游戏列表
extern NSString *const GMCloudGameList;

//查询指定云游戏平台
extern NSString *const GMPlatformDetail;

//APP游戏首页列表
extern NSString *const GMGameAppList;

//查询指定名称产品
extern NSString *const ProduceAppDetail;

//查询指定产品全部配置
extern NSString *const ProduceAppConfig;

//查询产品搜索关键词
extern NSString *const ProduceAppKeyword;

//查询灯光位置信息
extern NSString *const DevLightDetail;

//设备产品信息
extern NSString *const AppPruductList;





#pragma mark - AI智能体
extern NSString *const AgentChatBaseURL;

///智能体入房
extern NSString *const startVoiceChat;

///智能体退房
extern NSString *const stopVoiceChat;

///智能体更新
extern NSString *const updateVoiceChat;

///用户会员使用
extern NSString *const aiExpiredUserUse;

///用户游戏时长记录
extern NSString *const aiExpiredAddGameTime;

///AI下单支付
extern NSString *const aiOrderPay;

///苹果支付回调
extern NSString *const aiAppleStorePayNotify;
