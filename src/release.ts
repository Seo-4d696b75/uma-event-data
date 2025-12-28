import * as fs from 'fs';
import * as path from 'path';
import type { Event, IconData, ReleaseOwner, ReleaseData, ReleaseEvent, ReleaseChoice } from './schema.js';
import { ReleaseSupportOwnerSchema, ReleaseDataSchema } from './schema.js';

function readJson<T>(filePath: string): T {
  const content = fs.readFileSync(filePath, 'utf-8');
  return JSON.parse(content);
}

function assert(condition: boolean, message: string = ''): void {
  if (!condition) {
    console.error(message);
    process.exit(1);
  }
}

function checkName(name: string): string {
  // 空白文字が名前に混入して失敗する場合あり
  return name.replace(/\s+/g, '');
}

function main() {
  const oldData = readJson<ReleaseData>('data.json');
  const oldOwner = oldData.owner;
  const ids = new Set<number>();
  let maxId = Math.max(
    ...[...oldOwner.chara, ...oldOwner.support].map((e) => {
      assert(!ids.has(e.id), `id duplicated ${JSON.stringify(e)}`);
      ids.add(e.id);
      return e.id;
    })
  );

  const scenario: string[] = ['共通'];
  oldData.event
    .map((e) => e.owner)
    .filter((o) => o.type === 'scenario')
    .forEach((o) => {
      const name = o.name;
      if (!scenario.includes(name)) {
        scenario.push(name);
        console.log(`existing scenario ${name}`);
      }
    });

  const ownerData = readJson<IconData>('src/icon.json');
  const owner: ReleaseOwner = {
    chara: ownerData.chara.map((c) => {
      const name = checkName(c.n);
      const i = c.i;
      const list: string[] = [i];
      const second = `${path.basename(i, '.png')}_e.png`;
      if (fs.existsSync(`icon/${second}`)) {
        list.push(second);
      }

      // nameの変更を考慮
      const idx = oldOwner.chara.findIndex(
        (e) => e.name === name || JSON.stringify(e.icon) === JSON.stringify(list)
      );
      let id = maxId + 1;
      if (idx !== -1) {
        id = oldOwner.chara.splice(idx, 1)[0].id;
      } else {
        console.log(`new chara detected ${JSON.stringify(c)}`);
        maxId += 1;
      }

      return {
        id,
        name,
        icon: list,
      };
    }),
    support: ownerData.support.map((s) => {
      const name = checkName(s.n);
      const type = s.l.slice(0, 2);
      const rarityMatch = s.l.match(/S{0,2}R/);
      assert(rarityMatch !== null, `Invalid rarity: ${s.l}`);
      const rarity = rarityMatch![0];
      const idx = oldOwner.support.findIndex(
        (e) => e.name === name && e.type === type && e.rarity === rarity
      );
      let id = maxId + 1;
      if (idx !== -1) {
        id = oldOwner.support.splice(idx, 1)[0].id;
      } else {
        console.log(`new support detected ${JSON.stringify(s)}`);
        maxId += 1;
      }
      // zodスキーマでバリデーション
      return ReleaseSupportOwnerSchema.parse({
        id,
        name,
        icon: s.i,
        type,
        rarity,
      });
    }),
  };

  assert(oldOwner.chara.length === 0, `chara not found ${JSON.stringify(oldOwner.chara)}`);
  assert(oldOwner.support.length === 0, `support not found ${JSON.stringify(oldOwner.support)}`);

  const events = readJson<Event[]>('src/event.json');
  const event: ReleaseEvent[] = events.map((e) => {
    const title = e.e;
    const title_kana = e.k;
    const name = checkName(e.n);
    const cls = e.c;
    const choices: ReleaseChoice[] = e.choices.map((c) => ({
      name: c.n,
      message: c.t,
    }));
    if (cls === 'm' || name === '共通') {
      // イベント所有者なし
      if (!scenario.includes(name)) {
        console.log(`new scenario detected ${name}`);
        scenario.push(name);
      }
      console.log(`scenario ${name} (event name:${e.e})`);
      return {
        title,
        title_kana,
        owner: {
          type: 'scenario',
          name,
        },
        choices,
      }
    } else if (cls === 'c') {
      // 育成キャラ
      const o = owner.chara.find((c) => c.name === name);
      assert(o !== undefined, `育成キャラが見つかりません：${name}`);
      return {
        title,
        title_kana,
        owner: {
          type: 'chara',
          name,
          id: o!.id,
        },
        choices,
      }
    } else if (cls === 's') {
      // サポートカード
      const type = e.l?.slice(0, 2) || '';
      const rarityMatch = e.l?.match(/S{0,2}R/);
      assert(rarityMatch !== null, `Invalid rarity: ${e.l}`);
      const rarity = rarityMatch![0];
      const o = owner.support.find((s) => s.name === name && s.type === type && s.rarity === rarity);
      assert(o !== undefined, `サポーターが見つかりません：${name} ${type} ${rarity}`);
      return {
        title,
        title_kana,
        owner: {
          type: 'support',
          name,
          id: o!.id,
        },
        choices,
      }
    } else {
      throw new Error(`invalid event type 'e' ${JSON.stringify(e)}`);
    }
  });

  // zodスキーマでバリデーション
  const validatedData = ReleaseDataSchema.parse({
    event,
    owner,
  });

  fs.writeFileSync('data.json', JSON.stringify(validatedData, null, 2), 'utf-8');

  const size = fs.statSync('data.json').size;
  const d = new Date();
  const v = d.getFullYear() * 10000 + (d.getMonth() + 1) * 100 + d.getDate();

  const info = {
    version: v,
    size,
  };

  fs.writeFileSync('info.json', JSON.stringify(info, null, 2), 'utf-8');
}

main();

