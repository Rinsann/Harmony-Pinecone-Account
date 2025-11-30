import { relationalStore, ValuesBucket } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { AccountRecord, AccountStats, DateGroup, AccountData } from './Models';

// 核心修复：重新导出 Models 接口，解决所有 "not exported" 错误
export { AccountRecord, AccountStats, DateGroup, AccountData };

class DBUtil {
  private rdbStore: relationalStore.RdbStore | null = null;
  private tableName = 'ACCOUNT_TABLE';

  async initDB(context: common.UIAbilityContext): Promise<void> {
    const config: relationalStore.StoreConfig = {
      name: 'PineconeStore.db',
      securityLevel: relationalStore.SecurityLevel.S1
    };
    const sql = `CREATE TABLE IF NOT EXISTS ${this.tableName} ( id INTEGER PRIMARY KEY AUTOINCREMENT, amount REAL, type INTEGER, category TEXT, remark TEXT, date INTEGER )`;
    try {
      this.rdbStore = await relationalStore.getRdbStore(context, config);
      await this.rdbStore.executeSql(sql);
    } catch (err) {
      console.error('DB_INIT_ERR', JSON.stringify(err));
    }
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
          if (rec.type === 1) group.totalIn += amount;
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