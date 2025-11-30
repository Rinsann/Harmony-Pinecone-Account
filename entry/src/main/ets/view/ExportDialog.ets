import { Constants } from '../common/Constants';
import { DateUtil } from '../utils/DateUtil';

@CustomDialog
export struct ExportDialog {
  controller: CustomDialogController;
  // 回调函数：把选中的开始和结束时间传出去
  onConfirm: (start: number, end: number) => void = () => {};

  @State startDate: Date = new Date(new Date().getFullYear(), 0, 1); // 默认今年1月1日
  @State endDate: Date = new Date(); // 默认今天

  // 标记当前正在修改哪个日期 (0:开始, 1:结束)
  @State activePicker: number = 0;

  build() {
    Column() {
      // 1. 标题
      Text('账本导出')
        .fontSize(18).fontWeight(FontWeight.Bold)
        .fontColor(Constants.C_TEXT_TITLE)
        .margin({ top: 20, bottom: 30 })

      // 2. 日期选择区域
      Column() {
        Text('选择日期范围').fontSize(14).fontColor(Constants.C_TEXT_SECONDARY).width('100%').margin({ bottom: 10 })

        Column() {
          // 开始日期行
          Row() {
            Text('开始日期').fontSize(16).fontColor(Constants.C_TEXT_TITLE)
            Row() {
              Text(DateUtil.formatFullDate(this.startDate)).fontSize(16).fontColor(Constants.C_TEXT_TITLE)
              Text(' >').fontSize(16).fontColor(Constants.C_TEXT_SECONDARY)
            }
          }
          .width('100%').justifyContent(FlexAlign.SpaceBetween).padding(15)
          .backgroundColor(Constants.C_WHITE)
          .onClick(() => {
            this.activePicker = 0;
            this.openDatePicker(this.startDate);
          })

          Divider().color('#F0F0F0').strokeWidth(1)

          // 结束日期行
          Row() {
            Text('结束日期').fontSize(16).fontColor(Constants.C_TEXT_TITLE)
            Row() {
              Text(DateUtil.formatFullDate(this.endDate)).fontSize(16).fontColor(Constants.C_TEXT_TITLE)
              Text(' >').fontSize(16).fontColor(Constants.C_TEXT_SECONDARY)
            }
          }
          .width('100%').justifyContent(FlexAlign.SpaceBetween).padding(15)
          .backgroundColor(Constants.C_WHITE)
          .onClick(() => {
            this.activePicker = 1;
            this.openDatePicker(this.endDate);
          })
        }
        .borderRadius(12).clip(true) // 圆角包裹
      }
      .width('90%')

      // 3. 提示文案
      Column() {
        Text('1. 导出格式为 .csv (Excel兼容格式)').fontSize(12).fontColor(Constants.C_TEXT_SECONDARY).margin({ bottom: 4 })
        Text('2. 推荐使用 WPS 或 Excel 打开查看').fontSize(12).fontColor(Constants.C_TEXT_SECONDARY)
      }
      .width('90%').alignItems(HorizontalAlign.Start).margin({ top: 20, bottom: 30 })

      // 4. 确认按钮
      Button('确认导出')
        .width('90%').height(50)
        .backgroundColor(Constants.C_BRAND)
        .fontColor(Constants.C_WHITE)
        .fontSize(16).fontWeight(FontWeight.Bold)
        .onClick(() => {
          // 校验：结束时间不能早于开始时间
          if (this.endDate.getTime() < this.startDate.getTime()) {
            const temp = this.startDate;
            this.startDate = this.endDate;
            this.endDate = temp;
          }
          // 结束时间调到当天的 23:59:59
          const realEnd = new Date(this.endDate.getFullYear(), this.endDate.getMonth(), this.endDate.getDate(), 23, 59, 59);

          this.onConfirm(this.startDate.getTime(), realEnd.getTime());
          this.controller.close();
        })
        .margin({ bottom: 20 })
    }
    .width('90%')
    .backgroundColor('#F5F7F9') // 浅灰底色，模仿截图风格
    .borderRadius(20)
  }

  openDatePicker(defaultDate: Date) {
    DatePickerDialog.show({
      start: new Date("2020-01-01"),
      end: new Date("2100-12-31"),
      selected: defaultDate,
      onAccept: (value: DatePickerResult) => {
        if (value.year != undefined && value.month != undefined && value.day != undefined) {
          const newDate = new Date(value.year, value.month, value.day);
          if (this.activePicker === 0) {
            this.startDate = newDate;
          } else {
            this.endDate = newDate;
          }
        }
      }
    })
  }
}