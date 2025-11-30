export class DateUtil {
  static readonly WEEK_DAYS = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];

  static formatFullDate(date: Date): string {
    return `${date.getFullYear()}年${date.getMonth() + 1}月${date.getDate()}日`;
  }

  static formatShortDate(date: Date): string {
    return `${date.getMonth() + 1}月${date.getDate()}日`;
  }

  // 获取周几
  static getWeekDay(date: Date): string {
    return DateUtil.WEEK_DAYS[date.getDay()];
  }
}