import { Constants } from '../common/Constants';
import { DateUtil } from '../utils/DateUtil';
// 核心修复：现在 ReportPage 所有的类型都从 AccountService 统一导入
import { AccountService, AccountRecord, ChartStat, CategoryStat, RankItem, ReportData } from '../common/AccountService';

@Component
export struct ReportPage {
  @Prop @Watch('onRefreshTriggered') refreshFlag: number;

  @State startDate: Date = new Date();
  @State endDate: Date = new Date();
  @State reportType: number = 0;

  @State totalExpense: number = 0;
  @State totalIncome: number = 0;

  @State chartStats: ChartStat[] = [];
  @State expenseRank: RankItem[] = [];
  @State incomeRank: RankItem[] = [];

  @State rawList: AccountRecord[] = [];
  @State displayList: AccountRecord[] = [];

  @State @Watch('onToggleChange') showExpense: boolean = true;
  @State @Watch('onToggleChange') showIncome: boolean = true;
  @State sortByAmount: boolean = false;

  @State uiRefreshFlag: number = 0;

  scroller: Scroller = new Scroller();

  aboutToAppear() {
    this.initDateRange();
    setTimeout(() => { this.refreshData(); }, 100);
  }

  onRefreshTriggered() { this.refreshData(); }
  onPageShow() { this.refreshData(); }
  onToggleChange() { this.filterDisplayData(); }

  toggleListSort() {
    this.sortByAmount = !this.sortByAmount;
    this.filterDisplayData();
  }

  initDateRange() {
    const now = new Date();
    this.startDate = new Date(now.getFullYear(), now.getMonth(), 1);
    this.endDate = new Date(now.getFullYear(), now.getMonth() + 1, 0);
  }

  toggleType(type: number) {
    if (this.reportType === type) return;
    this.reportType = type;
    const year = this.startDate.getFullYear();
    if (type === 0) {
      const now = new Date();
      const targetMonth = (year === now.getFullYear()) ? now.getMonth() : 0;
      this.startDate = new Date(year, targetMonth, 1);
      this.endDate = new Date(year, targetMonth + 1, 0);
    } else {
      this.startDate = new Date(year, 0, 1);
      this.endDate = new Date(year, 11, 31);
    }
    this.refreshData();
  }

  showDatePicker() {
    if (this.reportType === 0) {
      DatePickerDialog.show({
        start: new Date("2020-01-01"), end: new Date("2100-12-31"), selected: this.startDate,
        onAccept: (value: DatePickerResult) => {
          if (value.year!=undefined && value.month!=undefined) {
            this.startDate = new Date(value.year, value.month, 1);
            this.endDate = new Date(value.year, value.month+1, 0);
            this.refreshData();
          }
        }
      });
    } else {
      const years: string[] = [];
      for(let i=2020; i<=2030; i++) years.push(i.toString());
      TextPickerDialog.show({
        range: years, selected: years.indexOf(this.startDate.getFullYear().toString()),
        onAccept: (val) => {
          const y = parseInt(years[val.index as number]);
          this.startDate = new Date(y, 0, 1);
          this.endDate = new Date(y, 11, 31);
          this.refreshData();
        }
      })
    }
  }

  async refreshData() {
    const data = await AccountService.getReportData(this.startDate, this.endDate, this.reportType);

    this.rawList = data.rawList;
    const stats = data.stats;

    // 1. 更新总额
    this.totalExpense = stats.tExp;
    this.totalIncome = stats.tInc;
    this.uiRefreshFlag++;

    // 2. 更新图表
    const chartRes = AccountService.getChartData(stats);
    const tempChart: ChartStat[] = [];
    const count = this.reportType === 0 ? new Date(this.startDate.getFullYear(), this.startDate.getMonth()+1, 0).getDate() : 12;

    for(let i=1; i<=count; i++) {
      const stat: ChartStat = {
        label: this.reportType === 0 ? i.toString() : `${i}月`,
        value: i,
        expense: chartRes.exp[i] || 0,
        income: chartRes.inc[i] || 0,
        maxAmount: chartRes.max
      };
      tempChart.push(stat);
    }
    this.chartStats = tempChart;

    this.expenseRank = data.expRank;
    this.incomeRank = data.incRank;

    this.filterDisplayData();

    if (this.reportType === 0) {
      setTimeout(() => { this.scrollToToday(); }, 50);
    } else {
      this.scroller.scrollTo({ xOffset: 0, yOffset: 0 });
    }
  }

  filterDisplayData() {
    let temp = this.rawList.filter(rec => {
      const type = Number(rec.type);
      if (type === 0) return this.showExpense;
      if (type === 1) return this.showIncome;
      return true;
    });

    if (this.sortByAmount) {
      temp.sort((a, b) => b.amount - a.amount);
    } else {
      temp.sort((a, b) => b.date - a.date);
    }

    this.displayList = temp;
  }

  scrollToToday() {
    const now = new Date();
    if(now.getTime() >= this.startDate.getTime() && now.getTime() <= this.endDate.getTime()) {
      const today = now.getDate();
      const xOffset = (today-4)*36;
      this.scroller.scrollTo({ xOffset: (xOffset > 0 ? xOffset : 0), yOffset: 0 });
    }
  }

  build() {
    Column() {
      Row() {
        Row() {
          Text(this.reportType === 0 ? `${this.startDate.getFullYear()}年${this.startDate.getMonth()+1}月` : `${this.startDate.getFullYear()}年`).fontSize(24).fontWeight(FontWeight.Bold).fontColor(Constants.C_TEXT_MAIN)
          Text('▼').fontSize(12).fontColor(Constants.C_TEXT_GRAY).margin({ left: 6 })
        }.onClick(() => this.showDatePicker())

        Blank()

        Row() {
          this.TypeBtn('月', 0); this.TypeBtn('年', 1)
        }.backgroundColor('#E8F5E9').borderRadius(16).padding(2)
      }.width('100%').padding({ top: 20, left: 20, right: 20, bottom: 10 }).justifyContent(FlexAlign.SpaceBetween)

      Scroll() {
        Column() {
          // 总览
          Column() {
            Row() {
              this.SwitchBtn('总支出', this.totalExpense, this.showExpense, true)
              Blank().width(20)
              this.SwitchBtn('总收入', this.totalIncome, this.showIncome, false)
            }.width('100%').justifyContent(FlexAlign.Start)
          }.width('90%').padding(20).margin({ bottom: 15 }).backgroundColor(Constants.C_WHITE).borderRadius(16).shadow({ radius: 10, color: '#05000000', offsetY: 5 })

          // 图表
          if (this.showExpense || this.showIncome) {
            Column() {
              Text(this.reportType === 0 ? '每日趋势' : '每月趋势').fontSize(16).fontWeight(FontWeight.Bold).width('100%').margin({ bottom: 20 })
              Scroll(this.scroller) {
                Row({ space: 16 }) {
                  ForEach(this.chartStats, (item: ChartStat) => {
                    Column() {
                      Stack({alignContent: Alignment.Bottom}) {
                        Column().width(16).height(120).backgroundColor('#FAFAFA').borderRadius(4)
                        Row({space:2}) {
                          if(this.showExpense) Column().width(this.showIncome?6:12).height(`${Math.max((item.expense/item.maxAmount)*80,0)}%`).backgroundColor(Constants.C_ACCENT_RED).borderRadius(4).alignSelf(ItemAlign.End)
                          if(this.showIncome) Column().width(this.showExpense?6:12).height(`${Math.max((item.income/item.maxAmount)*80,0)}%`).backgroundColor(Constants.C_MAIN).borderRadius(4).alignSelf(ItemAlign.End)
                        }.height(120).alignItems(VerticalAlign.Bottom)
                      }.height(120)
                      Text(item.label).fontSize(10).fontColor(Constants.C_TEXT_GRAY).margin({top:8})
                    }
                  })
                }.padding({right:20})
              }.scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Off).width('100%')
            }.width('90%').padding(15).margin({ bottom: 15 }).backgroundColor(Constants.C_WHITE).borderRadius(16)
          }

          // 排行榜 (内联)
          if (this.showExpense) this.RankCardView('支出排行榜', this.expenseRank, true)
          if (this.showIncome) this.RankCardView('收入排行榜', this.incomeRank, false)

          // 明细列表
          Column() {
            Row() {
              Text('收支明细').fontSize(16).fontWeight(FontWeight.Bold)
              Blank()
              Row() {
                Text(this.sortByAmount ? '💰' : '🕒').fontSize(10).margin({right: 4})
                Text(this.sortByAmount ? '按金额' : '按时间').fontSize(11).fontColor(Constants.C_BG_CARD).fontWeight(FontWeight.Medium)
              }.backgroundColor(Constants.C_BRAND).padding({left:10, right:10, top:4, bottom:4}).borderRadius(14).onClick(() => this.toggleListSort())
            }.width('100%').margin({ bottom: 15 }).alignItems(VerticalAlign.Center)

            if (this.displayList.length === 0) { Text('暂无记录').fontColor(Constants.C_TEXT_GRAY).fontSize(14).margin({ top: 10, bottom: 10 }) }
            else {
              List() {
                ForEach(this.displayList, (item: AccountRecord) => {
                  ListItem() {
                    Row() {
                      Circle({width:32, height:32}).fill(item.type===0?'#FFEBEE':'#E8F5E9')
                      Text(item.category.substring(0,1)).fontColor(item.type===0?Constants.C_ACCENT_RED:Constants.C_MAIN).fontSize(12).position({x:0,y:0}).width(32).height(32).textAlign(TextAlign.Center)
                      Column() {
                        Text(item.category).fontSize(14).fontColor('#333')
                        Text(DateUtil.formatFullDate(new Date(item.date))).fontSize(10).fontColor('#999').margin({top:2})
                      }.alignItems(HorizontalAlign.Start).margin({left:10}).layoutWeight(1)
                      Text((item.type===0?'-':'+')+item.amount.toFixed(2)).fontSize(16).fontWeight(FontWeight.Medium).fontColor(item.type===0?Constants.C_ACCENT_RED:Constants.C_MAIN)
                    }.width('100%').padding({top:10, bottom:10})
                  }
                })
              }.width('100%').height('auto')
            }
          }.width('90%').padding(15).margin({ bottom: 20 }).backgroundColor(Constants.C_WHITE).borderRadius(16)

        }.width('100%')
      }.scrollBar(BarState.Off).layoutWeight(1)
    }.width('100%').height('100%').backgroundColor(Constants.C_BG_PAGE)
  }

  @Builder TypeBtn(text: string, type: number) {
    Text(text).fontSize(14).fontColor(this.reportType === type ? Constants.C_WHITE : Constants.C_MAIN).backgroundColor(this.reportType === type ? Constants.C_MAIN : 'transparent').padding({ top: 4, bottom: 4, left: 16, right: 16 }).borderRadius(14).onClick(() => this.toggleType(type))
  }

  @Builder SwitchBtn(title: string, amount: number, isOn: boolean, isExpense: boolean) {
    Row() {
      Circle({ width: 16, height: 16 }).fill(isOn ? (isExpense ? Constants.C_ACCENT_RED : Constants.C_MAIN) : 'transparent').stroke(isExpense ? Constants.C_ACCENT_RED : Constants.C_MAIN).strokeWidth(1)
      Column() {
        Text(title).fontSize(12).fontColor(Constants.C_TEXT_GRAY)
        Text(`¥${amount.toFixed(2)}` + (this.uiRefreshFlag >= 0 ? '' : '')).fontSize(16).fontWeight(FontWeight.Bold).fontColor(isOn ? (isExpense ? Constants.C_ACCENT_RED : Constants.C_MAIN) : Constants.C_TEXT_GRAY)
      }.alignItems(HorizontalAlign.Start).margin({ left: 8 })
    }.onClick(() => { if (isExpense) this.showExpense = !this.showExpense; else this.showIncome = !this.showIncome; this.filterDisplayData(); })
  }

  @Builder RankCardView(title: string, list: RankItem[], isExpense: boolean) {
    Column() {
      Text(title).fontSize(16).fontWeight(FontWeight.Bold).width('100%').margin({ bottom: 15 })
      if (list.length === 0) { Text('暂无数据').fontColor(Constants.C_TEXT_GRAY).fontSize(14).margin({ top: 10, bottom: 10 }) }
      else {
        List() {
          ForEach(list, (item: RankItem) => {
            ListItem() {
              Column() {
                Row() {
                  Row() {
                    Circle({ width: 8, height: 8 }).fill(isExpense ? Constants.C_ACCENT_RED : Constants.C_MAIN).margin({ right: 8 })
                    Text(item.name).fontSize(14).fontWeight(FontWeight.Medium)
                    Text(` ${item.percent.toFixed(1)}%`).fontSize(12).fontColor(Constants.C_TEXT_GRAY).margin({ left: 5 })
                  }
                  Text(`¥ ${item.amount.toFixed(2)}`).fontSize(14).fontWeight(FontWeight.Bold)
                }.width('100%').justifyContent(FlexAlign.SpaceBetween).margin({ bottom: 8 })
                Progress({ value: item.percent, total: 100, type: ProgressType.Linear }).color(isExpense ? Constants.C_ACCENT_RED : Constants.C_MAIN).backgroundColor('#F0F0F0').style({ strokeWidth: 6 })
              }.padding({ top: 8, bottom: 8 })
            }
          })
        }.width('100%').height('auto')
      }
    }.width('90%').padding(15).margin({ bottom: 15 }).backgroundColor(Constants.C_WHITE).borderRadius(16)
  }
}