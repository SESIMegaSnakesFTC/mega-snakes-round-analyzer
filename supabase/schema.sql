-- SQL para Supabase
-- 1) Tabela de estado do usuário
create table if not exists public.user_state (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  updated_at timestamptz not null default now(),
  unique (user_id)
);

alter table public.user_state enable row level security;

create policy "Usuários veem apenas o próprio estado"
  on public.user_state
  for select
  using (auth.uid() = user_id);

create policy "Usuários criam apenas o próprio estado"
  on public.user_state
  for insert
  with check (auth.uid() = user_id);

create policy "Usuários atualizam apenas o próprio estado"
  on public.user_state
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create policy "Usuários deletam apenas o próprio estado"
  on public.user_state
  for delete
  using (auth.uid() = user_id);

-- 2) Perfil do usuário para Nome e e-mail
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Usuários leem apenas o próprio perfil"
  on public.profiles
  for select
  using (auth.uid() = id);

create policy "Usuários criam apenas o próprio perfil"
  on public.profiles
  for insert
  with check (auth.uid() = id);

create policy "Usuários atualizam apenas o próprio perfil"
  on public.profiles
  for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- 3) Trigger para manter o perfil sincronizado com auth.users
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'name', split_part(new.email, '@', 1)),
    new.email
  )
  on conflict (id) do update set
    full_name = excluded.full_name,
    email = excluded.email,
    updated_at = now();

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute procedure public.handle_new_user();

-- 4) Política opcional para leitura pública do nome do perfil
-- Essa política é opcional e não é necessária para o app funcionar.
-- Caso queira expor nome para qualquer usuário autenticado, use a linha abaixo:
-- create policy "Perfil visível para qualquer usuário autenticado" on public.profiles for select using (auth.role() = 'authenticated');

-- 5) Exemplo de estrutura do JSON salvo em user_state.data
-- {
--   "rounds": [
--     { "id": "uuid", "name": "Round 1", "score": 0, "notes": "" }
--   ],
--   "analyses": ["Texto da análise"],
--   "timer": { "elapsedSeconds": 0, "isRunning": false },
--   "settings": { "lastUpdatedAt": "2026-10-05T12:00:00.000Z" }
-- }
