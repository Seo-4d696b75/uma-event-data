# uma-event-data

「ウマ娘 プリティーダービー」の育成中に発生する選択肢ありイベントのデータを収集・管理するリポジトリ

`info.json`に最新データの情報があります  
```ts
{
  "version": number // 最新更新日時 yyyyMMdd
  "size": number // data.json のデータサイズ[byte]
}
```

## data format

- `data.json` : 画像以外のすべてのデータ
- `icon/*.png` : アイコン画像（育成ウマ娘・サポートカードのサムネイル画像）


`data.json`のデータ仕様  

```ts
{
  "event": Array<Event>
  "owner": {
    "chara": Array<Character>
    "support": Array<Supporter>
  }
}
```

各データクラス  
```ts
Event {
  "title": string // イベントタイトル
  "title_kana": string // イベントタイトル読み仮名
  "owner": string // このイベントが発生するキャラ名
  "choices": Array<EventChoice> // 選択肢
}
EventChoice {
  "name": string // 選択肢の表示名
  "message": string // 選択時の効果説明 改行文字"[br]"を含む
}
Character {
  "name": string // 育成ウマ娘の名前
  "icon": Array<string> // アイコン画像名（才能開花前後の複数の場合あり）
}
Supporter {
  "name": string // サポートカードのキャラクター名
  "type": string // サポートカードの種類
  "icon": string // アイコン画像名
}
```

## How to update & publish

1. データ更新
   - `event.json`: イベント選択肢
   - `icon.json`: 育成ウマ娘・サポートカード一覧
2. 画像データ更新  
   `$ python icon/download.py`
3. push  
   GithubActions が実行されて `data.json, info.json`を更新