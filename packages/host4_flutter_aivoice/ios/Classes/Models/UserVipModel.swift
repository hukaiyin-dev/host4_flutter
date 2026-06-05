import Foundation

/// 用户 VIP 状态
enum UserVipState: Int {
  case superVip       = 0  /// 超级会员
  case moreThreeDay   = 1  /// 会员剩余 > 3天
  case lessThreeDay   = 2  /// 会员剩余 ≤ 3天 且 > 0天
  case remainingCount = 3  /// 会员剩余次数
  case expired        = 4  /// 过期
  case noPurchase     = 5  /// 未购买
}

/// 用户 VIP 数据模型
struct UserVipModel: Codable {
  let useCount: Int
  let inviteCount: Int
  let gameTime: String?
  let useEndTime: String?
  let useDayCount: Int
  let isExpired: Bool
  let useEndTimeDay: Int
  let isSuperVip: Bool

  var currentState: UserVipState {
    if isSuperVip { return .superVip }
    if useEndTimeDay > 3 { return .moreThreeDay }
    if useEndTimeDay > 0 { return .lessThreeDay }
    if useCount > 0 { return .remainingCount }
    return .expired
  }
}
