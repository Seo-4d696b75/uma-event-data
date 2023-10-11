# uma-event-data

「ウマ娘 プリティーダービー」の育成中に発生する選択肢ありイベントのデータを収集・管理するリポジトリ

`info.json`に最新データの情報があります  
```ts
interface {
  version: number // 最新更新日時 yyyyMMdd
  size: number // data.json のデータサイズ[byte]
}
```

## data format

- `data.json` : 画像以外のすべてのデータ
- `icon/*.png` : アイコン画像（育成ウマ娘・サポートカードのサムネイル画像）


`data.json`のデータ仕様  

TypeScriptの要領で示します

```ts
// data.json
interface Data {
  event: Event[]
  owner: {
    chara: Character[]
    support: Supporter[]
  }
}
```

各データクラス  
```ts
interface Event {
  title: string // イベントタイトル
  title_kana: string // イベントタイトル読み仮名
  owner: EventOwner // このイベントが発生するキャラもしくはシナリオ
  choices: EventChoice[] // 選択肢
}
type EventOwner = {
  type: "scenario"
  name: string // "共通" | "URA" | "アオハル" | "クライマックス" | "グランドライブ" | "グランドマスターズ" | "プロジェクトL’Arc" など
} | {
  type: "chara" | "support" // 育成キャラ, サポートカード
  name: string
  id: number // Character,Supportに同idが存在する
}
interface EventChoice {
  name: string // 選択肢の表示名
  message: string // 選択時の効果説明 改行文字"[br]"を含む
}
interface Character {
  id: number
  name: string // 育成ウマ娘の名前
  icon: string[] // アイコン画像名（才能開花前後の複数の場合あり）画像ファイル"icon/${icon[idx]}.png"参照
}
interface Supporter {
  id: number
  name: string // サポートカードのキャラクター名
  icon: string // アイコン画像名
  type: "スピ" | "スタ" | "パワ" | "根性" | "賢さ" | "友人" | "グル"
  rarity: "R" | "SR" | "SSR"
}
```

## How to update & publish

[GithubActions](https://github.com/Seo-4d696b75/uma-event-data/actions)の`auto-update`ワークフローで実行

手動で起動、または毎時0:00に定期的に実行
