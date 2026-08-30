-- ============================================================
-- 明记餐饮 ERP · Supabase 建表脚本（一次性运行）
-- 用法：Supabase 控制台 → 左侧 SQL Editor → New query → 粘贴以下全部 → Run
-- ============================================================

-- 1) 数据表：每个分店/中央厨房的整份数据以一行 JSON 存放
--    key 例如 'erpv2:ck'、'erpv2:b1' ... 'erpv2:b11'
create table if not exists public.erp_store (
  key         text primary key,
  value       jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);

-- 2) 开启 Row Level Security
alter table public.erp_store enable row level security;

-- 3) 原型策略：允许 anon（匿名 public key）读写。
--    ⚠️ 说明：这是「零登录、打开即用」的原型级策略——任何拿到 anon key 的人
--    都能读写这张表。适合内部试用 / 演示。
--    上线要更安全时：删掉下面这条策略，改为启用 Supabase Auth（Google 登录）
--    并把 using / with check 换成 (auth.role() = 'authenticated')
--    或基于邮箱白名单的条件。
drop policy if exists "erp_store anon full access" on public.erp_store;
create policy "erp_store anon full access"
  on public.erp_store
  for all
  to anon
  using (true)
  with check (true);

-- 完成。回到 index.html，把 Project URL 和 anon public key 填进：
--   const SUPABASE_URL = "https://xxxxxxxx.supabase.co";
--   const SUPABASE_ANON_KEY = "eyJ...";
-- 保存后打开网站 → 设置页会显示「🟢 Supabase 云端同步 已启用」。
