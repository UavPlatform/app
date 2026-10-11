// 订单列表分栏（REQ-APP-002 用户侧状态机）：分栏名 = 阶段名，按卡片自身的阶段标签筛选，
// 分栏名、卡片标签、详情页头部永远是同一个词（「各阶段文案必须一致」）。
// 不按订单码分栏——MATCHING 同时覆盖「招募飞手中」「洽谈中」，PAID 同时覆盖
// 「待飞手确认」「进行中」，按码分栏必然出现分栏名与卡片标签不一致。

/// 兜底分栏：旁路终态 + 任何未被具体分栏覆盖的阶段。
const String orderFallbackTab = '售后/其他';

/// 分栏定义：(分栏名, 接受的阶段名集合)；null = 全部。
const List<(String, Set<String>?)> orderTabs = [
  ('全部', null),
  ('招募飞手中', {'招募飞手中'}),
  ('洽谈中', {'洽谈中'}),
  ('待支付', {'待支付'}),
  ('待飞手确认', {'待飞手确认'}),
  ('进行中', {'进行中'}),
  ('待验收', {'待验收'}),
  ('已完成', {'已完成'}),
  // REQ-APP-002 主状态机之外的旁路终态（后端 OrderStatus：取消/退款/争议）单独一栏；
  // 这一栏同时兜底：任何不属于前面各栏的阶段（如未来新增或未知的订单码）也归入这里，
  // 保证每张卡片都落在某个具体分栏里，而不是只出现在「全部」。
  (orderFallbackTab, {'已取消', '已退款', '争议中'}),
];

/// 前面各具体分栏覆盖的阶段名（不含兜底栏）。
final Set<String> _coveredLabels = {
  for (final t in orderTabs)
    if (t.$2 != null && t.$1 != orderFallbackTab) ...t.$2!,
};

/// 卡片是否属于该分栏：「全部」全收；兜底栏收旁路终态与所有未被具体分栏覆盖的阶段。
bool orderTabAccepts((String, Set<String>?) tab, String stage) {
  final labels = tab.$2;
  if (labels == null) return true;
  if (tab.$1 == orderFallbackTab) {
    return labels.contains(stage) || !_coveredLabels.contains(stage);
  }
  return labels.contains(stage);
}

/// 该阶段所在的具体分栏（不含「全部」）。
List<String> orderTabsFor(String stage) => [
  for (final t in orderTabs)
    if (t.$2 != null && orderTabAccepts(t, stage)) t.$1,
];
