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

// 型推論で型を取得
export type Choice = z.infer<typeof ChoiceSchema>;
export type Event = z.infer<typeof EventSchema>;
export type CharaImageData = z.infer<typeof CharaImageDataSchema>;
export type SupportImageData = z.infer<typeof SupportImageDataSchema>;
export type IconData = z.infer<typeof IconDataSchema>;

