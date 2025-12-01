import { relationalStore, ValuesBucket } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

// --- 基础数据结构 ---
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
// -----------------------------------------------------------------

export class DBUtil {
  private rdbStore: relationalStore.RdbStore | null = null;
  private tableName = 'ACCOUNT_TABLE';

  async initDB(context: common.UIAbilityContext): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: 'PineconeStore.db',
      securityLevel: relationalStore.SecurityLevel.S1
    };

    try {
      this.rdbStore = await relationalStore.getRdbStore(context, config);

      // --- 暴力重置：每次启动都删表重建，确保 Mock 数据一定进去 ---
      // ⚠️ 上线前请注释掉下面这一行！！
      await this.rdbStore.executeSql(`DROP TABLE IF EXISTS ${this.tableName}`);

      const sql = `CREATE TABLE IF NOT EXISTS ${this.tableName} ( id INTEGER PRIMARY KEY AUTOINCREMENT, amount REAL, type INTEGER, category TEXT, remark TEXT, date INTEGER )`;
      await this.rdbStore.executeSql(sql);

      // --- 强制注入 Mock 数据 ---
      console.info('DB: 开始强制注入 Mock 数据...');
      await this.generateMockData();
      console.info('DB: Mock 数据注入完成！');

    } catch (err) {
      console.error('DB_INIT_ERR', JSON.stringify(err));
    }
  }

  async generateMockData() {
    const now = new Date().getTime();

    // 本月数据 (11月)
    await this.insert({ id: 0, amount: 6666, type: 1, category: '工资', remark: '测试工资', date: now });
    await this.insert({ id: 0, amount: 33, type: 0, category: '餐饮', remark: '测试午饭', date: now });
    await this.insert({ id: 0, amount: 99, type: 0, category: '餐饮', remark: '晚饭', date: now + 86400000 }); // 明天
    await this.insert({ id: 0, amount: 500, type: 0, category: '交通', remark: '加油', date: now - 86400000 }); // 昨天

    // 上个月数据 (10月) - 用于测试月份切换
    await this.insert({ id: 0, amount: 99, type: 0, category: '交通', remark: '打车', date: now - 86400000 * 30 });
  }

  async queryAllList(): Promise<AccountRecord[]> {
    if (!this.rdbStore) return [];
    const predicates = new relationalStore.RdbPredicates(this.tableName);
    predicates.orderByDesc('date');
    const resultSet = await this.rdbStore.query(predicates);
    const list: AccountRecord[] = [];
    while (resultSet.goToNextRow()) {
      list.push({
        id: resultSet.getLong(resultSet.getColumnIndex('id')), amount: Number(resultSet.getDouble(resultSet.getColumnIndex('amount'))) || 0, type: Number(resultSet.getLong(resultSet.getColumnIndex('type'))), category: resultSet.getString(resultSet.getColumnIndex('category')), remark: resultSet.getString(resultSet.getColumnIndex('remark')), date: Number(resultSet.getLong(resultSet.getColumnIndex('date')))
      });
    }
    resultSet.close();
    return list;
  }

  async insert(record: AccountRecord): Promise<number> {
    if (!this.rdbStore) return -1;
    const value: ValuesBucket = {
      amount: record.amount, type: record.type, category: record.category, remark: record.remark, date: record.date
    };
    try {
      return await this.rdbStore.insert(this.tableName, value);
    } catch (err) {
      return -1;
    }
  }

  async delete(id: number): Promise<number> {
    if (!this.rdbStore) return -1;
    try {
      let predicates = new relationalStore.RdbPredicates(this.tableName);
      predicates.equalTo('id', id);
      return await this.rdbStore.delete(predicates);
    } catch (err) {
      return -1;
    }
  }

  async queryGrouped(): Promise<AccountData> {
    const emptyStats: AccountStats = { income: 0, expense: 0, balance: 0 };
    if (!this.rdbStore) return { groups: [], stats: emptyStats };

    try {
      let predicates = new relationalStore.RdbPredicates(this.tableName);
      predicates.orderByDesc('date');
      let resultSet = await this.rdbStore.query(predicates);

      let totalIncome = 0;
      let totalExpense = 0;
      let map = new Map<string, DateGroup>();
      let groupOrder: string[] = [];

      while (resultSet.goToNextRow()) {
        const id = resultSet.getLong(resultSet.getColumnIndex('id'));
        const amount = Number(resultSet.getDouble(resultSet.getColumnIndex('amount'))) || 0;
        const type = Number(resultSet.getLong(resultSet.getColumnIndex('type')));
        const category = resultSet.getString(resultSet.getColumnIndex('category'));
        const remark = resultSet.getString(resultSet.getColumnIndex('remark'));
        const date = Number(resultSet.getLong(resultSet.getColumnIndex('date')));

        const rec: AccountRecord = { id, amount, type, category, remark, date };

        if (type === 1) totalIncome += amount;
        else totalExpense += amount;

        const dateObj = new Date(date);
        const year = dateObj.getFullYear();
        const month = dateObj.getMonth() + 1;
        const day = dateObj.getDate();
        const weekday = dateObj.getDay();
        const uniqueKey = `${year}-${month}-${day}`;

        if (!map.has(uniqueKey)) {
          const newGroup: DateGroup = {
            groupKey: uniqueKey, year, month, day, weekday,
            totalIn: 0, totalOut: 0, records: []
          };
          map.set(uniqueKey, newGroup);
          groupOrder.push(uniqueKey);
        }

        let group = map.get(uniqueKey);
        if (group) {
          group.records.push(rec);
          if (type === 1) group.totalIn += amount;
          else group.totalOut += amount;
        }
      }
      resultSet.close();

      let groups: DateGroup[] = [];
      groupOrder.forEach(key => {
        const g = map.get(key);
        if (g) groups.push(g);
      });

      const finalStats: AccountStats = {
        income: totalIncome, expense: totalExpense, balance: totalIncome - totalExpense
      };

      const result: AccountData = { groups: groups, stats: finalStats };
      return result;

    } catch (err) {
      const emptyStats: AccountStats = { income: 0, expense: 0, balance: 0 };
      return { groups: [], stats: emptyStats };
    }
  }
}

export const dbUtil = new DBUtil();