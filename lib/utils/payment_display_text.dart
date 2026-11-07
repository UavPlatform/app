/// Compact copy for payment notices returned by the dispatch API, including old orders.
String paymentDisplayText(String text) => text
    .replaceAll('模拟支付尚未启用，需开发或测试环境及显式开关', '支付服务暂不可用')
    .replaceAll('模拟支付仅限显式启用的开发或测试环境', '支付服务暂不可用')
    .replaceAll('模拟支付', '支付')
    .replaceAll('模拟结算', '结算')
    .replaceAll('模拟退还', '退还')
    .replaceAll('模拟退回', '退回')
    .replaceAll('模拟退差额', '退差额')
    .replaceAll('，无真实资金变动。', '。')
    .replaceAll('无真实资金变动。', '');
