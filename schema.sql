-- MUNNY / SALDOUP — esquema inicial para Supabase (PostgreSQL)
-- Execute este arquivo no SQL Editor do seu projeto Supabase.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nome varchar(100) not null,
  email varchar(150) not null unique,
  data_cadastro timestamptz not null default now()
);

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  nome varchar(50) not null,
  tipo varchar(10) not null check (tipo in ('RECEITA','DESPESA')),
  created_at timestamptz not null default now(),
  unique(user_id, nome, tipo)
);

create table if not exists public.goals (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  nome varchar(100) not null,
  valor_alvo numeric(12,2) not null check (valor_alvo > 0),
  valor_atual numeric(12,2) not null default 0 check (valor_atual >= 0),
  prazo date not null,
  status varchar(12) not null default 'ATIVA' check (status in ('ATIVA','CONCLUIDA')),
  created_at timestamptz not null default now()
);

create table if not exists public.transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  category_id uuid not null references public.categories(id) on delete restrict,
  goal_id uuid references public.goals(id) on delete set null,
  tipo varchar(10) not null check (tipo in ('RECEITA','DESPESA')),
  valor numeric(12,2) not null check (valor > 0),
  descricao varchar(150) not null,
  data date not null,
  status varchar(12) not null check (status in ('EFETIVADA','AGENDADA')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_categories_user on public.categories(user_id);
create index if not exists idx_goals_user on public.goals(user_id);
create index if not exists idx_transactions_user_date on public.transactions(user_id, data desc);
create index if not exists idx_transactions_goal on public.transactions(goal_id);

-- Cria o perfil e categorias iniciais quando um usuário confirma o cadastro.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  display_name text;
begin
  display_name := coalesce(new.raw_user_meta_data->>'nome', split_part(new.email, '@', 1));
  insert into public.profiles(id, nome, email)
  values (new.id, display_name, new.email)
  on conflict (id) do nothing;

  insert into public.categories(user_id, nome, tipo) values
    (new.id, 'Salário', 'RECEITA'),
    (new.id, 'Outras receitas', 'RECEITA'),
    (new.id, 'Alimentação', 'DESPESA'),
    (new.id, 'Transporte', 'DESPESA'),
    (new.id, 'Moradia', 'DESPESA'),
    (new.id, 'Lazer', 'DESPESA'),
    (new.id, 'Saúde', 'DESPESA'),
    (new.id, 'Educação', 'DESPESA'),
    (new.id, 'Outras despesas', 'DESPESA')
  on conflict (user_id, nome, tipo) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure public.handle_new_user();

-- Atualiza updated_at automaticamente.
create or replace function public.set_updated_at()
returns trigger language plpgsql as $$
begin new.updated_at = now(); return new; end;
$$;
drop trigger if exists transactions_updated_at on public.transactions;
create trigger transactions_updated_at before update on public.transactions
for each row execute procedure public.set_updated_at();

-- Row Level Security: cada usuário acessa somente os próprios registros.
alter table public.profiles enable row level security;
alter table public.categories enable row level security;
alter table public.goals enable row level security;
alter table public.transactions enable row level security;

drop policy if exists "profile_select_own" on public.profiles;
create policy "profile_select_own" on public.profiles for select to authenticated using (id = auth.uid());
drop policy if exists "profile_update_own" on public.profiles;
create policy "profile_update_own" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

drop policy if exists "categories_select_own" on public.categories;
create policy "categories_select_own" on public.categories for select to authenticated using (user_id = auth.uid());
drop policy if exists "categories_insert_own" on public.categories;
create policy "categories_insert_own" on public.categories for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "categories_update_own" on public.categories;
create policy "categories_update_own" on public.categories for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "categories_delete_own" on public.categories;
create policy "categories_delete_own" on public.categories for delete to authenticated using (user_id = auth.uid());

drop policy if exists "goals_select_own" on public.goals;
create policy "goals_select_own" on public.goals for select to authenticated using (user_id = auth.uid());
drop policy if exists "goals_insert_own" on public.goals;
create policy "goals_insert_own" on public.goals for insert to authenticated with check (user_id = auth.uid());
drop policy if exists "goals_update_own" on public.goals;
create policy "goals_update_own" on public.goals for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());
drop policy if exists "goals_delete_own" on public.goals;
create policy "goals_delete_own" on public.goals for delete to authenticated using (user_id = auth.uid());

drop policy if exists "transactions_select_own" on public.transactions;
create policy "transactions_select_own" on public.transactions for select to authenticated using (user_id = auth.uid());
drop policy if exists "transactions_insert_own" on public.transactions;
create policy "transactions_insert_own" on public.transactions for insert to authenticated with check (
  user_id = auth.uid()
  and exists (select 1 from public.categories c where c.id = category_id and c.user_id = auth.uid() and c.tipo = tipo)
  and (goal_id is null or exists (select 1 from public.goals g where g.id = goal_id and g.user_id = auth.uid()))
);
drop policy if exists "transactions_update_own" on public.transactions;
create policy "transactions_update_own" on public.transactions for update to authenticated using (user_id = auth.uid()) with check (
  user_id = auth.uid()
  and exists (select 1 from public.categories c where c.id = category_id and c.user_id = auth.uid() and c.tipo = tipo)
  and (goal_id is null or exists (select 1 from public.goals g where g.id = goal_id and g.user_id = auth.uid()))
);
drop policy if exists "transactions_delete_own" on public.transactions;
create policy "transactions_delete_own" on public.transactions for delete to authenticated using (user_id = auth.uid());

-- Recomendado: em Authentication > URL Configuration, configure a URL local e a URL publicada.
