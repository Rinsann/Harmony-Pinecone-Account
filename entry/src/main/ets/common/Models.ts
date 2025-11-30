// entry/src/main/ets/common/Models.ts

export interface AccountRecord {
  id: number;
  amount: number;
  type: number; // 0:支出, 1:收入
  category: string;
  remark: string;
  date: number; // 毫秒级时间戳
}

export interface AccountStats {
  income: number;
  expense: number;
  balance: number;
}

export interface DateGroup {
  groupKey: string;
  year: number;
  month: number;
  day: number;
  weekday: number;
  totalIn: number;
  totalOut: number;
  records: AccountRecord[];
}

export interface AccountData {
  groups: DateGroup[];
  stats: AccountStats;
}

export interface ProcessedData {
  records: AccountRecord[];
  stats: AccountStats;
  groups: DateGroup[];
}

// 修复点：确保 CategoryStat 存在
export interface CategoryStat {
  name: string;
  amount: number;
  percent: number;
}
export interface RankItem extends CategoryStat {}

export interface CalcResult {
  tExp: number;
  tInc: number;
  expMap: Map<string, number>;
  incMap: Map<string, number>;
  expBuckets: number[];
  incBuckets: number[];
  bucketSize: number;
}

export interface ReportData {
  rawList: AccountRecord[];
  stats: CalcResult;
  expRank: RankItem[];
  incRank: RankItem[];
}

export interface ChartStat {
  label: string;
  value: number;
  expense: number;
  income: number;
  maxAmount: number;
}

export interface ChartData {
  exp: number[];
  inc: number[];
  max: number;
}