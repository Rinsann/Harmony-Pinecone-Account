import { Constants } from '../common/Constants';
import { DateUtil } from '../utils/DateUtil';
import { dbUtil } from '../common/DBUtil';

@Component
export struct AccountInputSheet {
  @Link isSheetShow: boolean;
  onSaveSuccess: () => void = () => {};

  @State inputAmount: string = '';
  @State inputType: number = 0; // 0支出
  @State inputCategory: string = '餐饮';
  @State inputRemark: string = '';
  @State inputDate: Date = new Date();

  @State expenseList: string[] = Constants.DEFAULT_EXPENSE;
  @State incomeList: string[] = Constants.DEFAULT_INCOME;
  @State isAddingCategory: boolean = false;
  @State newCategoryName: string = '';

  aboutToAppear() {
    this.loadCategories();
  }

  loadCategories() {
    try {
      const storedExpense = AppStorage.get<string[]>(Constants.KEY_EXPENSE);
      if (storedExpense) this.expenseList = storedExpense;
      const storedIncome = AppStorage.get<string[]>(Constants.KEY_INCOME);
      if (storedIncome) this.incomeList = storedIncome;
    } catch (e) {}
  }

  saveCategories() {
    AppStorage.setOrCreate(Constants.KEY_EXPENSE, this.expenseList);
    AppStorage.setOrCreate(Constants.KEY_INCOME, this.incomeList);
  }

  getCurrentList(): string[] {
    return this.inputType === 0 ? this.expenseList : this.incomeList;
  }

  async handleSave() {
    if (!this.inputAmount) return;
    await dbUtil.insert({
      id: 0,
      amount: parseFloat(this.inputAmount),
      type: this.inputType,
      category: this.inputCategory,
      remark: this.inputRemark,
      date: this.inputDate.getTime()
    });
    this.inputAmount = '';
    this.inputRemark = '';
    this.isSheetShow = false;
    this.onSaveSuccess();
  }

  showDatePicker() {
    DatePickerDialog.show({
      start: new Date("2020-01-01"),
      end: new Date("2100-12-31"),
      selected: this.inputDate,
      onAccept: (value: DatePickerResult) => {
        if (value.year != undefined && value.month != undefined && value.day != undefined) {
          this.inputDate = new Date(value.year, value.month, value.day);
        }
      }
    })
  }

  build() {
    Column() {
      // 1. 顶部操作栏
      Row() {
        Blank().width(32)

        Row() {
          this.TypeTab('支出', 0)
          this.TypeTab('收入', 1)
        }

        Text('×')
          .fontSize(36)
          .fontColor(Constants.C_TEXT_GRAY)
          .fontWeight(FontWeight.Regular)
          .onClick(() => this.isSheetShow = false)
          .width(32)
          .textAlign(TextAlign.End)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ top: 20, bottom: 15, left: 20, right: 20 })

      // 2. 金额输入
      Row() {
        Text('¥').fontSize(24).fontWeight(FontWeight.Bold).margin({ bottom: 6 })
        TextInput({ text: this.inputAmount, placeholder: '0.00' })
          .fontSize(36).fontWeight(FontWeight.Bold)
        // 核心修复：支出红，收入绿
          .fontColor(this.inputType === 0 ? Constants.C_ACCENT_RED : Constants.C_ACCENT_GREEN)
          .caretColor(Constants.C_BRAND)
          .type(InputType.NUMBER_DECIMAL)
          .backgroundColor(Color.Transparent)
          .layoutWeight(1)
          .onChange((val) => this.inputAmount = val)
      }.width('90%').border({ width: { bottom: 1 }, color: '#EEE' }).padding({ bottom: 5 })

      // 3. 日期选择
      Row() {
        Text('📅').fontSize(16).margin({ right: 5 })
        Text(DateUtil.formatFullDate(this.inputDate))
          .fontSize(14).fontColor(Constants.C_TEXT_MAIN)
        Text(' (点击修改)').fontSize(12).fontColor(Constants.C_TEXT_GRAY)
      }.width('90%').padding({ top: 12, bottom: 12 }).onClick(() => this.showDatePicker())

      // 4. 分类区域
      Column() {
        if (this.isAddingCategory) {
          this.AddCategoryView()
        } else {
          this.CategoryGridView()
        }
      }

      // 5. 底部保存
      Row() {
        TextInput({ text: this.inputRemark, placeholder: '备注...' })
          .backgroundColor('#F5F5F5').height(45).borderRadius(8).layoutWeight(1).margin({ right: 12 })
          .onChange((val) => this.inputRemark = val)
        Button('保存').backgroundColor(Constants.C_BRAND).fontColor(Constants.C_WHITE).height(45).width(90)
          .onClick(() => this.handleSave())
      }.width('90%').margin({ bottom: 20, top: 10 })
    }
    .backgroundColor(Constants.C_WHITE)
    .borderRadius({ topLeft: 16, topRight: 16 })
  }

  @Builder TypeTab(text: string, type: number) {
    Text(text)
      .fontColor(this.inputType === type ? Constants.C_WHITE : Constants.C_BRAND)
      .backgroundColor(this.inputType === type ? Constants.C_BRAND : '#F1F3F5')
      .padding({ top: 8, bottom: 8, left: 30, right: 30 })
      .borderRadius(type === 0 ? { topLeft: 20, bottomLeft: 20 } : { topRight: 20, bottomRight: 20 })
      .fontSize(18)
      .fontWeight(FontWeight.Medium)
      .onClick(() => {
        this.inputType = type;
        this.inputCategory = this.getCurrentList()[0];
        this.isAddingCategory = false;
      })
  }

  @Builder AddCategoryView() {
    Column() {
      Text('输入新分类名称').fontSize(14).fontColor(Constants.C_TEXT_GRAY).margin({ bottom: 10, top: 10 })
      TextInput({ text: this.newCategoryName, placeholder: '例如：装修、分红' })
        .height(45).width('80%').backgroundColor('#F5F5F5').borderRadius(8)
        .onChange((val) => this.newCategoryName = val).margin({ bottom: 20 })
      Row() {
        Button('取消').backgroundColor('#EEE').fontColor('#666')
          .onClick(() => { this.isAddingCategory = false; this.newCategoryName = ''; }).width('35%').margin({ right: 10 })
        Button('确定').backgroundColor(Constants.C_BRAND).fontColor(Constants.C_WHITE)
          .onClick(() => {
            if (this.newCategoryName.trim().length > 0) {
              if (this.inputType === 0) this.expenseList.push(this.newCategoryName);
              else this.incomeList.push(this.newCategoryName);
              this.inputCategory = this.newCategoryName;
              this.saveCategories();
              this.isAddingCategory = false;
              this.newCategoryName = '';
            }
          }).width('35%')
      }
    }.height(240).justifyContent(FlexAlign.Center)
  }

  @Builder CategoryGridView() {
    Column() {
      Text('选择分类').width('100%').fontSize(12).fontColor(Constants.C_TEXT_GRAY).margin({ bottom: 10 })
      Grid() {
        ForEach(this.getCurrentList(), (item: string) => {
          GridItem() {
            Column() {
              Circle({ width: 48, height: 48 }).fill(this.inputCategory === item ? Constants.C_BRAND : '#F5F5F5')
              Text(item.substring(0, 1)).fontSize(16).fontWeight(FontWeight.Bold)
                .fontColor(this.inputCategory === item ? Constants.C_WHITE : Constants.C_TEXT_GRAY)
                .position({ x: 0, y: 0 }).width(48).height(48).textAlign(TextAlign.Center)
              Text(item).fontSize(12).fontColor(Constants.C_TEXT_GRAY).margin({ top: 4 })
            }
            .onClick(() => this.inputCategory = item)
          }
        })
        GridItem() {
          Column() {
            Circle({ width: 48, height: 48 }).fill('#F5F5F5')
            Text('+').fontSize(24).fontColor(Constants.C_TEXT_GRAY)
              .position({ x: 0, y: 0 }).width(48).height(48).textAlign(TextAlign.Center)
            Text('添加').fontSize(12).fontColor(Constants.C_TEXT_GRAY).margin({ top: 4 })
          }
          .onClick(() => { this.newCategoryName = ''; this.isAddingCategory = true; })
        }
      }.columnsTemplate('1fr 1fr 1fr 1fr 1fr').rowsGap(15).height(220)
    }.width('95%')
  }
}