import { z } from 'zod';

// サポートタイプの定義
export const SUPPORT_TYPES = ['スピ', 'スタ', 'パワ', '根性', '賢さ', '友人', 'グル'] as const;

// 選択肢のスキーマ
export const ChoiceSchema = z.object({
  n: z.string(), // 選択肢名
  t: z.string(), // メッセージ
});

// イベントのスキーマ
export const EventSchema = z.object({
  e: z.string(), // タイトル
  n: z.string(), // オーナー名
  c: z.string(), // クラス（'m', 'c', 's'のいずれか）
  l: z.string().optional(), // "通常"など
  a: z.string().optional(), // 不明
  k: z.string(), // カナ
  choices: z.array(ChoiceSchema), // 選択肢の配列
});

// キャラクター画像データのスキーマ
export const CharaImageDataSchema = z.object({
  n: z.string(), // 名前（必須）
  c: z.literal('c'), // クラス（'c'固定）
  i: z.string(), // 画像ファイル名（必須）
});

// サポート画像データのスキーマ
export const SupportImageDataSchema = z.object({
  n: z.string(), // 名前（必須）
  l: z.string() // ラベル（必須）
    .refine((val) => {
      // 最初の2文字がサポートタイプに含まれるかチェック
      const type = val.slice(0, 2);
      return SUPPORT_TYPES.includes(type as typeof SUPPORT_TYPES[number]);
    }, { message: 'ラベルの最初の2文字はサポートタイプ（スピ、スタ、パワ、根性、賢さ、友人、グル）である必要があります' })
    .refine((val) => {
      // レアリティパターン（S{0,2}R）が含まれるかチェック
      return /S{0,2}R/.test(val);
    }, { message: 'ラベルにレアリティパターン（S{0,2}R）が含まれている必要があります' }),
  c: z.literal('s'), // クラス（'s'固定）
  i: z.string(), // 画像ファイル名（必須）
});

// IconDataのスキーマ
export const IconDataSchema = z.object({
  support: z.array(SupportImageDataSchema),
  chara: z.array(CharaImageDataSchema),
});

// リリース用のスキーマ（変換後のデータ形式）

// リリース用の選択肢スキーマ
export const ReleaseChoiceSchema = z.object({
  name: z.string(), // 選択肢名
  message: z.string(), // メッセージ
});

// リリース用のイベントオーナースキーマ（union型）
export const ReleaseEventOwnerSchema = z.union([
  // scenarioタイプ：idなし
  z.object({
    type: z.literal('scenario'),
    name: z.string(), // "共通" | "URA" | "アオハル" | "クライマックス" | "グランドライブ" | "グランドマスターズ" | "プロジェクトL'Arc" など
  }),
  // charaまたはsupportタイプ：id必須
  z.object({
    type: z.union([z.literal('chara'), z.literal('support')]),
    name: z.string(),
    id: z.number(), // Character,Supportに同idが存在する
  }),
]);

// リリース用のイベントスキーマ
export const ReleaseEventSchema = z.object({
  title: z.string(), // タイトル
  title_kana: z.string(), // カナ
  owner: ReleaseEventOwnerSchema, // オーナー
  choices: z.array(ReleaseChoiceSchema), // 選択肢の配列
});

// リリース用のキャラクターオーナースキーマ
export const ReleaseCharaOwnerSchema = z.object({
  id: z.number(), // ID
  name: z.string(), // 名前
  icon: z.array(z.string()), // アイコン（文字列または配列）
});

// リリース用のサポートオーナースキーマ
export const ReleaseSupportOwnerSchema = z.object({
  id: z.number(), // ID
  name: z.string(), // サポートカードのキャラクター名
  icon: z.string(), // アイコン画像名
  type: z.enum(['スピ', 'スタ', 'パワ', '根性', '賢さ', '友人', 'グル']), // タイプ
  rarity: z.enum(['R', 'SR', 'SSR']), // レアリティ
});

// リリース用のオーナースキーマ
export const ReleaseOwnerSchema = z.object({
  support: z.array(ReleaseSupportOwnerSchema), // サポートの配列
  chara: z.array(ReleaseCharaOwnerSchema), // キャラクターの配列
});

// リリース用のデータスキーマ
export const ReleaseDataSchema = z.object({
  event: z.array(ReleaseEventSchema), // イベントの配列
  owner: ReleaseOwnerSchema, // オーナー
});

// 型推論で型を取得
export type Choice = z.infer<typeof ChoiceSchema>;
export type Event = z.infer<typeof EventSchema>;
export type CharaImageData = z.infer<typeof CharaImageDataSchema>;
export type SupportImageData = z.infer<typeof SupportImageDataSchema>;
export type IconData = z.infer<typeof IconDataSchema>;

// リリース用の型
export type ReleaseChoice = z.infer<typeof ReleaseChoiceSchema>;
export type ReleaseEventOwner = z.infer<typeof ReleaseEventOwnerSchema>;
export type ReleaseEvent = z.infer<typeof ReleaseEventSchema>;
export type ReleaseCharaOwner = z.infer<typeof ReleaseCharaOwnerSchema>;
export type ReleaseSupportOwner = z.infer<typeof ReleaseSupportOwnerSchema>;
export type ReleaseOwner = z.infer<typeof ReleaseOwnerSchema>;
export type ReleaseData = z.infer<typeof ReleaseDataSchema>;
