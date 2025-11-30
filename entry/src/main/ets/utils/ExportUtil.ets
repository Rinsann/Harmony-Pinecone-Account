import { dbUtil } from '../common/DBUtil';
import { DateUtil } from './DateUtil';
import { picker, fileIo } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';

export class ExportUtil {

  // 导出指定时间段的数据
  static async exportData(context: common.UIAbilityContext, startTime: number, endTime: number) {
    try {
      // 1. 获取所有数据 (DBUtil 会负责查库)
      const allRecords = await dbUtil.queryAllList();

      // 2. 内存过滤
      const targetRecords = allRecords.filter(rec => rec.date >= startTime && rec.date <= endTime);

      if (targetRecords.length === 0) {
        promptAction.showToast({ message: '该时间段内没有账单可导出' });
        return;
      }

      // 3. 构建 CSV 内容 (BOM头防乱码)
      // 表头：人类可读 + 机器可读 (用于未来恢复)
      let csvContent = '\uFEFF交易时间,收支类型,分类,金额,备注,时间戳(系统用),类型ID(系统用)\n';

      targetRecords.forEach(rec => {
        const dateObj = new Date(rec.date);

        // 格式化为标准格式: 2025-11-29 14:30:15 (Excel 友好)
        const y = dateObj.getFullYear();
        const m = (dateObj.getMonth() + 1).toString().padStart(2, '0');
        const d = dateObj.getDate().toString().padStart(2, '0');
        const h = dateObj.getHours().toString().padStart(2, '0');
        const min = dateObj.getMinutes().toString().padStart(2, '0');
        const s = dateObj.getSeconds().toString().padStart(2, '0');
        const dateStr = `${y}-${m}-${d} ${h}:${min}:${s}`;

        const typeStr = rec.type === 0 ? '支出' : '收入';

        // 处理备注中的特殊字符 (逗号、换行、双引号)
        let remark = rec.remark || '';
        remark = remark.replace(/"/g, '""');
        if (remark.includes(',') || remark.includes('\n')) {
          remark = `"${remark}"`;
        }

        // 拼接一行
        csvContent += `${dateStr},${typeStr},${rec.category},${rec.amount},${remark},${rec.date},${rec.type}\n`;
      });

      // 4. 生成文件名 (例如：松果账单_备份_20250101-20251231.csv)
      const startStr = ExportUtil.formatDateForFile(new Date(startTime));
      const endStr = ExportUtil.formatDateForFile(new Date(endTime));
      const fileName = `松果账单_备份_${startStr}-${endStr}.csv`;

      // 5. 拉起系统文件保存器
      const savePicker = new picker.DocumentViewPicker(context);
      const saveOptions = new picker.DocumentSaveOptions();
      saveOptions.newFileNames = [fileName];

      const uris = await savePicker.save(saveOptions);

      if (uris && uris.length > 0) {
        // 写入文件
        const uri = uris[0];
        const file = await fileIo.open(uri, fileIo.OpenMode.READ_WRITE);
        // 写入内容
        await fileIo.write(file.fd, csvContent);
        // 关闭文件流
        await fileIo.close(file.fd);

        promptAction.showToast({ message: `成功导出 ${targetRecords.length} 条数据` });
      }

    } catch (err) {
      const error = err as BusinessError;
      console.error(`[ExportUtil] Failed: ${error.code}, ${error.message}`);
      promptAction.showToast({ message: '导出取消或失败' });
    }
  }

  // 辅助方法：生成 yyyyMMdd 格式的日期字符串
  private static formatDateForFile(date: Date): string {
    const y = date.getFullYear();
    const m = (date.getMonth() + 1).toString().padStart(2, '0');
    const d = date.getDate().toString().padStart(2, '0');
    return `${y}${m}${d}`;
  }
}