export class Constants {
  // --- 1. 核心品牌色 (松果绿/青黛色) ---
  static readonly C_BRAND = '#26A69A';
  static readonly C_BRAND_LIGHT = '#E0F2F1';
  static readonly C_HEADER_BG = '#B2DFDB';

  // --- 2. 业务色 ---
  static readonly C_ACCENT_RED = '#FF5252';   // 支出红
  static readonly C_ACCENT_GREEN = '#4CAF50'; // 收入绿

  // --- 3. 文字色 ---
  static readonly C_TEXT_TITLE = '#1F292E';  // 深黑标题
  static readonly C_TEXT_MAIN = '#333333';   // 正文
  static readonly C_TEXT_SECONDARY = '#969799'; // 次要灰 (修复报错的关键!)
  static readonly C_TEXT_GRAY = '#999999';

  // --- 4. 背景与通用 ---
  static readonly C_BG_PAGE = '#F6F7F9';
  static readonly C_BG_CARD = '#FFFFFF';
  static readonly C_BG = '#F7F8FA';
  static readonly C_WHITE = '#FFFFFF';

  // --- 5. 兼容旧代码的别名 (防报错) ---
  static readonly C_MAIN = '#26A69A';
  static readonly R_CARD = 24;

  // Keys
  static readonly KEY_EXPENSE = 'pinecone_expense_list_v1';
  static readonly KEY_INCOME = 'pinecone_income_list_v1';

  static readonly DEFAULT_EXPENSE = ['餐饮', '交通', '购物', '日用', '娱乐', '住房', '医疗', '其他'];
  static readonly DEFAULT_INCOME = ['工资', '奖金', '理财', '兼职', '礼金', '其他'];
}