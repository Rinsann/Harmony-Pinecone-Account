import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import { dbUtil } from '../common/DBUtil';
import { AccountRecord, DateGroup, AccountStats } from '../common/Models';
import { AccountService } from '../common/AccountService';
import { Constants } from '../common/Constants';
import { DateUtil } from '../utils/DateUtil';
import { AccountInputSheet } from '../view/AccountInputSheet';
import { ReportPage } from '../view/ReportPage';
import { ExportDialog } from '../view/ExportDialog';
import { ExportUtil } from '../utils/ExportUtil';

@Entry
@Component
struct Index {
  @State currentIndex: number = 0;
  @State isSheetShow: boolean = false;
  @State refreshFlag: number = 0;

  async aboutToAppear() {
    let context = getContext(this) as common.UIAbilityContext;
    await dbUtil.initDB(context);
    this.refreshFlag++;
  }

  @Builder TabBuilder(title: string, targetIndex: number, iconStr: string) {
    Column() {
      Text(iconStr).fontSize(24).opacity(this.currentIndex === targetIndex ? 1 : 0.4).margin({ bottom: 4 })
      Text(title).fontColor(this.currentIndex === targetIndex ? Constants.C_BRAND : '#999999').fontSize(10)
    }.width('100%').height(50).justifyContent(FlexAlign.Center)
    .onClick(() => { this.currentIndex = targetIndex; })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Tabs({ barPosition: BarPosition.End, index: this.currentIndex }) {
        TabContent() {
          BillView({ isSheetShow: $isSheetShow, refreshFlag: $refreshFlag })
        }.tabBar(this.TabBuilder('账单', 0, '📝'))

        TabContent() {
          ReportPage({ refreshFlag: this.refreshFlag })
        }.tabBar(this.TabBuilder('报表', 1, '📊'))

        TabContent() {
          MinePage()
        }.tabBar(this.TabBuilder('我的', 2, '👤'))
      }
      .scrollable(false)
      .onChange((index) => {
        this.currentIndex = index;
        if (index === 1) this.refreshFlag++;
      })
    }
    .bindSheet($$this.isSheetShow, this.AccountInputSheetWrapper(), {
      height: SheetSize.MEDIUM, dragBar: true, backgroundColor: Constants.C_BG_CARD, showClose: false,
      onDisappear: () => { this.isSheetShow = false }
    })
  }

  @Builder AccountInputSheetWrapper() {
    AccountInputSheet({
      isSheetShow: $isSheetShow,
      onSaveSuccess: () => { this.refreshFlag++; }
    })
  }
}

@Component
struct BillView {
  @Link isSheetShow: boolean;
  @Link @Watch('onRefresh') refreshFlag: number;
  @State groups: DateGroup[] = [];
  @State stats: AccountStats = { income: 0, expense: 0, balance: 0 };
  @State sortByAmount: boolean = false;

  aboutToAppear() { this.refresh(); }
  onRefresh() { this.refresh(); }

  async refresh() {
    const now = new Date();
    const start = new Date(now.getFullYear(), now.getMonth(), 1).getTime();
    const end = new Date(now.getFullYear(), now.getMonth() + 1, 0).getTime() + 86400000 - 1;
    const result = await AccountService.getProcessedList(start, end, this.sortByAmount, 'all');
    this.groups = result.groups;
    this.stats = result.stats;
  }

  toggleSort() {
    this.sortByAmount = !this.sortByAmount;
    this.refresh();
  }

  @Builder SwipeDelete(id: number) {
    Button('删除').backgroundColor(Constants.C_ACCENT_RED).fontColor(Constants.C_BG_CARD).width(60).height('100%')
      .type(ButtonType.Normal).onClick(async () => { await dbUtil.delete(id); this.refresh(); })
  }

  @Builder GroupHeader(group: DateGroup) {
    Row() {
      if (group.year === 0) {
        Text('本月金额排行 (从大到小)').fontSize(14).fontWeight(FontWeight.Bold).fontColor(Constants.C_TEXT_SECONDARY)
      } else {
        Row() {
          Text(`${group.month}月${group.day}日`).fontSize(15).fontWeight(FontWeight.Medium).fontColor(Constants.C_TEXT_TITLE).margin({ right: 8 })
          Text(DateUtil.WEEK_DAYS[group.weekday]).fontSize(12).fontColor(Constants.C_TEXT_SECONDARY)
        }.alignItems(VerticalAlign.Bottom)
        Blank()
        Text(`支 ${group.totalOut.toFixed(2)}`).fontSize(12).fontColor(Constants.C_TEXT_SECONDARY)
      }
    }.width('100%').padding({ left: 16, right: 16, top: 16, bottom: 8 })
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Stack() {
        Text('PINE').fontSize(100).fontWeight(900).fontColor('rgba(255,255,255,0.15)').position({ x: -20, y: 40 }).rotate({ angle: -5 })
        Text('CONE').fontSize(100).fontWeight(900).fontColor('rgba(255,255,255,0.15)').position({ x: 80, y: 100 })
      }.width('100%').height(320).backgroundColor(Constants.C_HEADER_BG)

      Column() {
        Row() {
          Text('松果账本').fontSize(20).fontWeight(FontWeight.Bold).fontColor(Constants.C_WHITE)
          Blank()
          Text('🎫').fontSize(20).margin({ right: 15 })
          Text('👑').fontSize(20)
        }.width('100%').padding({ top: 40, left: 20, right: 20, bottom: 10 })

        Column() {
          Row() { Text('本月支出(元)').fontSize(12).fontColor(Constants.C_TEXT_SECONDARY); Blank() }.width('100%').margin({ bottom: 5 })
          Text(`${this.stats.expense.toFixed(2)}`).fontSize(46).fontWeight(FontWeight.Bold).fontColor(Constants.C_TEXT_TITLE).margin({ bottom: 20 })
          Row() {
            Column() { Text('本月收入').fontSize(11).fontColor(Constants.C_TEXT_SECONDARY); Text(`${this.stats.income.toFixed(2)}`).fontSize(15).fontColor(Constants.C_TEXT_TITLE).fontWeight(FontWeight.Medium).margin({top:2}) }.alignItems(HorizontalAlign.Start)
            Blank().width(40)
            Column() { Text('月结余').fontSize(11).fontColor(Constants.C_TEXT_SECONDARY); Text(`${this.stats.balance.toFixed(2)}`).fontSize(15).fontColor(Constants.C_TEXT_TITLE).fontWeight(FontWeight.Medium).margin({top:2}) }.alignItems(HorizontalAlign.Start)
          }.width('100%').margin({ bottom: 25 })
          Button('记一笔').width('100%').height(50).backgroundColor(Constants.C_BRAND).fontColor(Constants.C_BG_CARD).fontSize(17).fontWeight(FontWeight.Medium)
            .shadow({ radius: 10, color: 'rgba(135, 198, 152, 0.4)', offsetY: 5 }).onClick(() => { this.isSheetShow = true })
        }.width('92%').padding(24).backgroundColor(Constants.C_BG_CARD).borderRadius(Constants.R_CARD).shadow({ radius: 30, color: 'rgba(0,0,0,0.06)', offsetY: 10 }).margin({ top: 10, bottom: 20 })

        List({ space: 10 }) {
          ListItem() {
            Row() {
              Text('近期账单').fontSize(16).fontWeight(FontWeight.Bold).fontColor(Constants.C_TEXT_TITLE)
              Blank()
              Row() {
                Text(this.sortByAmount ? '💰' : '🕒').fontSize(10).margin({right: 4})
                Text(this.sortByAmount ? '按金额' : '按时间').fontSize(11).fontColor(Constants.C_BG_CARD).fontWeight(FontWeight.Medium)
              }.backgroundColor(Constants.C_BRAND).padding({left:10, right:10, top:4, bottom:4}).borderRadius(14).onClick(() => { this.toggleSort(); })
            }.width('100%').padding({left: 15, right: 15, bottom: 5})
          }

          ForEach(this.groups, (group: DateGroup) => {
            ListItemGroup({ header: this.GroupHeader(group) }) {
              ForEach(group.records, (item: AccountRecord) => {
                ListItem() {
                  Row() {
                    Stack({ alignContent: Alignment.Center }) {
                      Circle({ width: 40, height: 40 }).fill('#F5F7FA')
                      Text(item.category.substring(0, 1)).fontSize(16).fontColor(Constants.C_TEXT_TITLE)
                    }
                    Column() {
                      Text(item.category).fontSize(16).fontColor(Constants.C_TEXT_TITLE).fontWeight(FontWeight.Medium)
                      if (this.sortByAmount) { Text(DateUtil.formatShortDate(new Date(item.date))).fontSize(12).fontColor(Constants.C_TEXT_SECONDARY).margin({top:4}) }
                      else if(item.remark) { Text(item.remark).fontSize(12).fontColor(Constants.C_TEXT_SECONDARY).margin({top:4}) }
                    }.alignItems(HorizontalAlign.Start).layoutWeight(1).margin({ left: 12 })
                    Text(item.amount.toFixed(2)).fontSize(18).fontWeight(FontWeight.Bold).fontColor(item.type === 0 ? Constants.C_ACCENT_RED : Constants.C_ACCENT_GREEN)
                  }.width('100%').padding({ left: 15, right: 15, top: 14, bottom: 14 }).backgroundColor(Constants.C_BG_CARD)
                }.swipeAction({ end: this.SwipeDelete(item.id) })
              })
            }
          })
          ListItem().height(100)
        }.layoutWeight(1).scrollBar(BarState.Off)
      }.width('100%').height('100%').backgroundColor(Color.Transparent)
    }.width('100%').height('100%').backgroundColor(Constants.C_BG_PAGE)
  }
}

@Component
struct MinePage {
  exportDialogController: CustomDialogController = new CustomDialogController({
    builder: ExportDialog({
      onConfirm: (start: number, end: number) => {
        const context = getContext(this) as common.UIAbilityContext;
        ExportUtil.exportData(context, start, end);
      }
    }),
    autoCancel: true, alignment: DialogAlignment.Bottom, customStyle: true
  });

  build() {
    Column() {
      Stack({ alignContent: Alignment.Bottom }) {
        Column().width('100%').height(220).backgroundColor(Constants.C_HEADER_BG)
        Row() {
          // 绿色圆形 LOGO
          Stack({ alignContent: Alignment.Center }) {
            Circle({ width: 72, height: 72 }).fill(Constants.C_BRAND)
            Text('松').fontSize(32).fontWeight(FontWeight.Bold).fontColor(Constants.C_WHITE)
          }.margin({ right: 15 })

          Column() {
            Text('Hi, 记账人').fontSize(20).fontWeight(FontWeight.Bold)
            Text('坚持记账第 1 天').fontSize(12).fontColor('#666').margin({top: 4})
          }.alignItems(HorizontalAlign.Start)
          Blank()
          Text('打卡').fontSize(12).fontColor(Constants.C_TEXT_TITLE).padding({left:12, right:12, top:6, bottom:6}).border({width:1, color:Constants.C_TEXT_TITLE}).borderRadius(14)
        }.width('92%').padding(24).backgroundColor(Constants.C_BG_CARD).borderRadius(Constants.R_CARD).shadow({ radius: 20, color: 'rgba(0,0,0,0.05)', offsetY: 5 }).margin({ bottom: -40 })
      }

      // 导出导入功能
      Column() {
        Row() { Row() { Text('📤').fontSize(18).margin({ right: 12 }); Text('导出账单数据 (Excel)').fontSize(16).fontColor(Constants.C_TEXT_TITLE) }.alignItems(VerticalAlign.Center); Text('›').fontSize(20).fontColor(Constants.C_TEXT_SECONDARY) }
        .width('100%').justifyContent(FlexAlign.SpaceBetween).padding(20).onClick(() => { this.exportDialogController.open(); })
        Divider().color('#F5F7F9').strokeWidth(1).padding({ left: 50 })
        Row() { Row() { Text('📥').fontSize(18).margin({ right: 12 }); Text('导入账单数据').fontSize(16).fontColor(Constants.C_TEXT_TITLE) }.alignItems(VerticalAlign.Center); Text('›').fontSize(20).fontColor(Constants.C_TEXT_SECONDARY) }
        .width('100%').justifyContent(FlexAlign.SpaceBetween).padding(20).onClick(() => { promptAction.showToast({ message: '导入功能开发中...' }); })
      }.backgroundColor(Constants.C_BG_CARD).borderRadius(16).margin({ left: 20, right: 20, top: 60 })
    }.width('100%').height('100%').backgroundColor(Constants.C_BG_PAGE)
  }
}