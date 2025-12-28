// データの更新
// 更新ファイル： src/event.json src/icon.json icon/*

import axios from 'axios';
import * as fs from 'fs';
import { z } from 'zod';
import { EventSchema, IconDataSchema } from './schema.js';

async function getHttpText(url: string): Promise<string | null> {
  try {
    const response = await axios.get<string>(url, {
      responseType: 'text',
    });
    return response.data;
  } catch (err) {
    if (axios.isAxiosError(err)) {
      const status = err.response?.status;
      const message = err.message;
      console.log(`network error uri:${url} code:${status} message:${message}`);
    } else {
      const errorMessage = err instanceof Error ? err.message : String(err);
      console.log(`network error uri:${url} error:${errorMessage}`);
    }
    return null;
  }
}

async function getHttpBinary(url: string): Promise<Buffer | null> {
  try {
    const response = await axios.get<ArrayBuffer>(url, {
      responseType: 'arraybuffer',
    });
    return Buffer.from(response.data);
  } catch (err) {
    if (axios.isAxiosError(err)) {
      const status = err.response?.status;
      const message = err.message;
      console.log(`network error uri:${url} code:${status} message:${message}`);
    } else {
      const errorMessage = err instanceof Error ? err.message : String(err);
      console.log(`network error uri:${url} error:${errorMessage}`);
    }
    return null;
  }
}

async function getImgs(list: {i: string}[]): Promise<void> {  
  for (const d of list) {
    const name = d.i;
    const url = `https://img.gamewith.jp/article_tools/uma-musume/gacha/${name}`;
    const img = await getHttpBinary(url);
    if (img) {
      fs.writeFileSync(`./icon/${name}`, img);
    }
  }
}

// JSONライクな文字列を標準JSONに変換する
// - 文字列はシングルクォーテーション
// - 値は文字列・整数値のみ
// - 末端のカンマも許す
function convertJson(str: string): any {
  // シングルクォートで囲まれた文字列をダブルクォートに変換
  // エスケープされたシングルクォート（\'）を一時的に置換してから処理
  let converted = str;
  
  // エスケープされたシングルクォートを一時的なプレースホルダーに置換
  const escapedPlaceholder = '__ESCAPED_SINGLE_QUOTE__';
  converted = converted.replace(/\\'/g, escapedPlaceholder);
  
  // シングルクォートで囲まれた文字列をダブルクォートに変換
  // 文字列内のダブルクォートはエスケープ
  converted = converted.replace(/'([^']*)'/g, (_match, content) => {
    // プレースホルダーを元のエスケープシーケンスに戻し、ダブルクォートをエスケープ
    const escaped = content
      .replace(new RegExp(escapedPlaceholder, 'g'), "'")
      .replace(/"/g, '\\"');
    return `"${escaped}"`;
  });
  
  // 末尾のカンマを削除（オブジェクト/配列の閉じ括弧の前のカンマ）
  // ネストされた構造にも対応するため、再帰的に処理
  converted = converted.replace(/,(\s*[}\]])/g, '$1');
  
  // 標準のJSON.parseを使用
  try {
    return JSON.parse(converted);
  } catch (error) {
    throw new Error(`Failed to parse JSON-like string: ${error instanceof Error ? error.message : String(error)}`);
  }
}

async function main() {
  // update data.json
  const eventRes = await getHttpText('https://gamewith-tool.s3-ap-northeast-1.amazonaws.com/uma-musume/female_event_datas.js');
  if (!eventRes) {
    console.error('Failed to fetch event data');
    process.exit(1);
  }
  const eventMatch = /window.eventDatas\[.+?\]\s?=\s?(?<events>\[.+\]);/sm.exec(eventRes);
  if (!eventMatch || !eventMatch.groups) {
    console.error('Failed to parse event data');
    process.exit(1);
  }
  const eventDataRaw = convertJson(eventMatch.groups.events);
  // zodスキーマでバリデーション
  const eventData = z.array(EventSchema).parse(eventDataRaw);
  fs.writeFileSync('src/event.json', JSON.stringify(eventData, null, 2), 'utf-8');

  // update icon.json
  const iconRes = await getHttpText('https://gamewith-tool.s3-ap-northeast-1.amazonaws.com/uma-musume/common_event_datas.js');
  if (!iconRes) {
    console.error('Failed to fetch icon data');
    process.exit(1);
  }
  const iconMatch = /const imageDatas\s*=\s*(?<data>\{.+\});/sm.exec(iconRes);
  if (!iconMatch || !iconMatch.groups) {
    console.error('Failed to parse icon data');
    process.exit(1);
  }
  const iconDataRaw = convertJson(iconMatch.groups.data);
  // zodスキーマでバリデーション
  const iconData = IconDataSchema.parse(iconDataRaw);
  fs.writeFileSync('src/icon.json', JSON.stringify(iconData, null, 2), 'utf-8');

  // update icon/*.png
  await getImgs(iconData.support);
  await getImgs(iconData.chara);
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

