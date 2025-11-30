import { dbUtil } from './DBUtil';
import { AccountRecord, DateGroup, AccountStats, ProcessedData, CalcResult, RankItem, ChartData, ReportData, CategoryStat, ChartStat } from './Models';

// 导出所有需要的类型，供 ReportPage 等使用
export { AccountRecord, DateGroup, AccountStats, ProcessedData, CalcResult, RankItem, ChartData, ReportData, CategoryStat, ChartStat };

export class AccountService {

  static async getRawList(startTime?: number, endTime?: number): Promise<AccountRecord[]> {
    const result = await dbUtil.queryGrouped();
    let allRecords: AccountRecord[] = [];
    result.groups.forEach(group => {
      allRecords.push(...group.records);
    });
    if (startTime !== undefined && endTime !== undefined) {
      allRecords = allRecords.filter(rec => rec.date >= startTime && rec.date <= endTime);
    }
    return allRecords;
  }

  static async getProcessedList(startTime: number, endTime: number, sortByAmount: boolean, filterType: string): Promise<ProcessedData> {
    let records = await AccountService.getRawList(startTime, endTime);

    if (filterType === 'expense') records = records.filter(r => r.type === 0);
    else if (filterType === 'income') records = records.filter(r => r.type === 1);

    let totalIn = 0;
    let totalOut = 0;
    records.forEach(r => {
      if (r.type === 1) totalIn += r.amount;
      else totalOut += r.amount;
    });

    if (sortByAmount) records.sort((a, b) => b.amount - a.amount);
    else records.sort((a, b) => b.date - a.date);

    let finalGroups: DateGroup[] = [];
    if (sortByAmount) {
      finalGroups = [{
        groupKey: 'SORTED', year: 0, month: 0, day: 0, weekday: 0,
        totalIn: totalIn, totalOut: totalOut, records: records
      }];
    } else {
      const map = new Map<string, DateGroup>();
      const order: string[] = [];
      records.forEach(rec => {
        const d = new Date(rec.date);
        const key = `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
        if (!map.has(key)) {
          const group: DateGroup = {
            groupKey: key, year: d.getFullYear(), month: d.getMonth() + 1, day: d.getDate(), weekday: d.getDay(),
            totalIn: 0, totalOut: 0, records: []
          };
          map.set(key, group);
          order.push(key);
        }
        const g = map.get(key);
        if (g) {
          g.records.push(rec);
          if (rec.type === 1) g.totalIn += rec.amount;
          else g.totalOut += rec.amount;
        }
      });
      order.forEach(k => {
        const g = map.get(k);
        if (g) finalGroups.push(g);
      });
    }

    const result: ProcessedData = {
      records: records,
      stats: { income: totalIn, expense: totalOut, balance: totalIn - totalOut },
      groups: finalGroups
    };
    return result;
  }

  static async getReportData(startDate: Date, endDate: Date, reportType: number): Promise<ReportData> {
    return new Promise(async (resolve) => {
      const rawList = await AccountService.getRawList(startDate.getTime(), endDate.getTime() + 86400000);
      rawList.sort((a, b) => b.date - a.date);

      let tExp = 0;
      let tInc = 0;
      const expMap = new Map<string, number>();
      const incMap = new Map<string, number>();

      const bucketSize = reportType === 0 ? 32 : 13;
      const expBuckets = new Array<number>(bucketSize).fill(0);
      const incBuckets = new Array<number>(bucketSize).fill(0);

      rawList.forEach(rec => {
        const amt = Number(rec.amount) || 0;
        const type = Number(rec.type);
        const date = new Date(rec.date);
        let idx = reportType === 0 ? date.getDate() : (date.getMonth() + 1);
        if (idx >= bucketSize) idx = 0;

        if (type === 0) {
          tExp += amt;
          expMap.set(rec.category, (expMap.get(rec.category) || 0) + amt);
          expBuckets[idx] += amt;
        } else {
          tInc += amt;
          const oldVal = incMap.get(rec.category) || 0;
          incMap.set(rec.category, oldVal + amt);
          // 核心修复点：收入金额必须加到收入桶 (incBuckets)
          incBuckets[idx] += amt;
        }
      });

      const stats: CalcResult = {
        tExp, tInc, expMap, incMap, expBuckets, incBuckets, bucketSize
      };

      const expRank = AccountService.generateRank(expMap, tExp);
      const incRank = AccountService.generateRank(incMap, tInc);

      resolve({ rawList, stats, expRank, incRank });
    });
  }

  private static generateRank(map: Map<string, number>, total: number): RankItem[] {
    return Array.from(map.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map((item): RankItem => ({
        name: item[0],
        amount: item[1],
        percent: total > 0 ? (item[1] / total) * 100 : 0
      }));
  }

  static getChartData(stats: CalcResult): ChartData {
    const exp = stats.expBuckets;
    const inc = stats.incBuckets;
    const size = stats.bucketSize;
    let max = 0;
    for(let i=1; i<size; i++) {
      if (exp[i] > max) max = exp[i];
      if (inc[i] > max) max = inc[i];
    }
    if(max === 0) max = 1;
    return { exp, inc, max };
  }
}