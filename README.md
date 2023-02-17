### 語系檔匯入方式

#### 文檔路徑

[Excel Link](https://docs.google.com/spreadsheets/d/15i4-gzsconR5OuUHzckjCZf2pFRzem4abh0L-svYIl4/edit#gid=1194671734)

#### **設定檔(config.ini)**

sheet_id: GOOGLE SHEET ID

ignored_sheet_tags: 若表單名稱包含這個欄位的字串則會跳過不轉檔，此欄位用```','```區隔

culture_codes: 需翻譯語系, 對應表格最上方欄位及匯出路徑，此欄位用```','```區隔

target_folder: 匯出位置根目錄

#### Pre-Steps
1. 要執行Python3要先去[下載](https://www.python.org/downloads/)及安裝 
2. 安裝 `pip`

   ```
   curl https://bootstrap.pypa.io/get-pip.py | sudo python3
   ```

3. terminal 執行
   ```
   python3 -m pip install openpyxl
   python3 -m pip install requests
   python3 -m pip install pandas
   ```

#### 調整文檔Steps
1. 調整/新增/修改文檔
2. Terminal -> cd {project path} -> python3 i18n.py
