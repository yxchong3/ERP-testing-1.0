-- ============================================================
-- 明记餐饮 ERP · Supabase 建表脚本
-- 用法：Supabase 控制台 → SQL Editor → New query → 粘贴全部 → Run
-- 已经跑过第 1 版的，只需再跑「第 2 部分」即可（重复运行安全）。
-- ============================================================

-- ========== 第 1 部分：业务数据表 erp_store ==========
create table if not exists public.erp_store (
  key         text primary key,
  value       jsonb not null default '{}'::jsonb,
  updated_at  timestamptz not null default now()
);
alter table public.erp_store enable row level security;

-- 收紧：仅「已登录」用户可读写业务数据（未登录看不到任何东西）
drop policy if exists "erp_store anon full access" on public.erp_store;      -- 移除旧的匿名策略
drop policy if exists "erp_store authed full access" on public.erp_store;
create policy "erp_store authed full access"
  on public.erp_store for all
  to authenticated
  using (true) with check (true);

-- ========== 第 2 部分：白名单 / 用户目录 erp_users ==========
-- 只有列在此表且 active=true 的邮箱能进入系统；岗位/分店由管理员分配。
create table if not exists public.erp_users (
  email       text primary key,
  name        text,
  role        text not null default 'staff',   -- owner / area / manager / headchef / staff
  outlet      text default 'b1',               -- 所属分店 id：ck / b1 ... b11
  active      boolean not null default true,
  created_at  timestamptz not null default now()
);
alter table public.erp_users enable row level security;

-- 已登录用户可读写白名单（应用层已限制只有 老板/区域副经理 能看到管理面板）。
-- 想更严格时：把写入策略换成「仅 owner/area 可改」——可另外加一个基于 email→role 的
-- SQL 函数做判断，需要的话让我帮你加。
drop policy if exists "erp_users authed read" on public.erp_users;
drop policy if exists "erp_users authed write" on public.erp_users;
create policy "erp_users authed read"
  on public.erp_users for select
  to authenticated using (true);
create policy "erp_users authed write"
  on public.erp_users for all
  to authenticated using (true) with check (true);

-- ============================================================
-- 首次使用：
-- 1) 上面跑完后，去 Authentication → Providers → Email 确认已开启；
--    并在 Authentication → Providers → Email 里把「Confirm email」关掉，
--    这样员工注册后可立即登录（不用等确认邮件）。
-- 2) 打开网站 → 用你的邮箱点「注册账号」。因为白名单此刻为空，
--    第一位注册者会被自动设为『老板』。之后就能在
--    设置 → 白名单/用户管理 里添加其他员工并分配岗位/分店。
--    （也可以不靠自动引导，直接在这里手动插入第一位老板：）
-- insert into public.erp_users (email,name,role,outlet,active)
--   values ('you@example.com','老板','owner','b1',true)
--   on conflict (email) do update set role=excluded.role, active=true;
-- ============================================================
