# ObjectViewer
Salesforceのオブジェクト、項目を一覧表示します

## Description
* ObjectViewerを開くと、オブジェクトを一覧表示します

#### オブジェクト一覧の機能
* オブジェクト名、API参照名、プレフィックスを表示
* 項目一覧ページを別タブで開く
* ビューページ(/[プレフィックス])を別タブで開く

#### 項目一覧の機能
* 項目名、API参照名、データ型、参照先オブジェクト、桁数、選択リスト値、数式、カスタムオブジェクトか、必須かを表示
* チェックボックスをONにした項目で、SELECT文を生成
* 項目一覧をCSV出力
* 被参照オブジェクトの一覧を表示

#### 注意
* 階層型は、ユーザオブジェクトへの参照関係項目として表示します
* 積み上げ集計は、集計対象オブジェクトと、集計方法は表示されません

## Licence

[MIT](https://github.com/yeaoh/ObjectViewer/blob/master/LICENSE)


## Author
[yeaoh](https://github.com/yeaoh)
