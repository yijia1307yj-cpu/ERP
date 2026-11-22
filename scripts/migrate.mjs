// 迁移入口：包装 node-pg-migrate，避免在 npm script 里直接调 CLI（Windows 下 .bin shim 不稳）。
//   node scripts/migrate.mjs up            对 DATABASE_URL 执行全部未跑的迁移
//   node scripts/migrate.mjs down [n]      对 DATABASE_URL 回滚 n 个（默认 1）
//   node scripts/migrate.mjs check         在临时库上 up → down(全部) → up，然后删库；主库一行都不碰
import { fileURLToPath } from 'node:url';
import { runner } from 'node-pg-migrate';
import pg from 'pg';

const dir = fileURLToPath(new URL('../db/migrations', import.meta.url));
const [command, countArg] = process.argv.slice(2);

const databaseUrl = process.env.DATABASE_URL;
if (!databaseUrl) {
  console.error('DATABASE_URL 未设置（复制 .env.example 为 .env，或在环境变量里提供）');
  process.exit(1);
}

const migrate = (url, direction, count) =>
  runner({
    databaseUrl: url,
    dir,
    direction,
    count,
    migrationsTable: 'pgmigrations',
    checkOrder: true,
    singleTransaction: true,
    log: (msg) => console.log(`  ${msg}`),
  });

async function check() {
  const adminUrl = new URL(databaseUrl);
  adminUrl.pathname = '/postgres';
  const tempDb = `erp_check_${process.pid}_${Date.now()}`;
  const tempUrl = new URL(databaseUrl);
  tempUrl.pathname = `/${tempDb}`;

  const admin = new pg.Client({ connectionString: adminUrl.toString() });
  await admin.connect();
  await admin.query(`CREATE DATABASE "${tempDb}"`);
  console.log(`临时库 ${tempDb} 已创建`);
  try {
    console.log('[1/3] up');
    await migrate(tempUrl.toString(), 'up', Infinity);
    console.log('[2/3] down（全部）');
    await migrate(tempUrl.toString(), 'down', Infinity);
    console.log('[3/3] up（验证可重复执行）');
    await migrate(tempUrl.toString(), 'up', Infinity);
  } finally {
    await admin.query(`DROP DATABASE IF EXISTS "${tempDb}" WITH (FORCE)`);
    await admin.end();
    console.log(`临时库 ${tempDb} 已删除`);
  }
}

switch (command) {
  case 'up':
    await migrate(databaseUrl, 'up', Infinity);
    break;
  case 'down':
    await migrate(databaseUrl, 'down', countArg ? Number(countArg) : 1);
    break;
  case 'check':
    await check();
    console.log('迁移检查通过');
    break;
  default:
    console.error('用法：node scripts/migrate.mjs <up|down [n]|check>');
    process.exit(1);
}
