-- SQL para Supabase: Mega Snakes Round Analyzer
-- Schema com autenticação, perfil de usuário e persistência de dados por usuário
-- Row Level Security (RLS) garante isolamento total dos dados

-- ============================================================================
-- 1) TABELA DE PERFIL DO USUÁRIO
-- ============================================================================
-- Armazena nome completo e e-mail do usuário
-- Sincronizada automaticamente com auth.users via trigger

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  email text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

-- Usuários só podem ler seu próprio perfil
create policy "Usuários leem apenas o próprio perfil"
  on public.profiles
  for select
  using (auth.uid() = id);

-- Usuários só podem criar seu próprio perfil
create policy "Usuários criam apenas o próprio perfil"
  on public.profiles
  for insert
  with check (auth.uid() = id);

-- Usuários só podem atualizar seu próprio perfil
create policy "Usuários atualizam apenas o próprio perfil"
  on public.profiles
  for update
  using (auth.uid() = id)
  with check (auth.uid() = id);

-- ============================================================================
-- 2) TABELA DE ESTADO DO USUÁRIO
-- ============================================================================
-- Armazena todo o estado do aplicativo como JSON
-- Inclui rounds, análises, configurações, histórico, etc.
-- user_id identifica o proprietário dos dados
-- RLS garante que cada usuário só acessa seus próprios dados

create table if not exists public.user_state (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  data jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id)
);

alter table public.user_state enable row level security;

-- Usuários só podem ler seu próprio estado
create policy "Usuários veem apenas o próprio estado"
  on public.user_state
  for select
  using (auth.uid() = user_id);

-- Usuários só podem criar seu próprio estado
create policy "Usuários criam apenas o próprio estado"
  on public.user_state
  for insert
  with check (auth.uid() = user_id);

-- Usuários só podem atualizar seu próprio estado
create policy "Usuários atualizam apenas o próprio estado"
  on public.user_state
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Usuários só podem deletar seu próprio estado
create policy "Usuários deletam apenas o próprio estado"
  on public.user_state
  for delete
  using (auth.uid() = user_id);

-- ============================================================================
-- 3) FUNÇÃO PARA SINCRONIZAR PERFIL COM AUTH.USERS
-- ============================================================================
-- Executada automaticamente quando um novo usuário é criado
-- Extrai o nome do metadata ou usa a parte do e-mail
-- Garante que sempre há um perfil associado ao usuário

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

-- Trigger: executado após novo usuário ser criado em auth.users
create trigger on_auth_user_created
  after insert on auth.users
  for each row
  execute procedure public.handle_new_user();

-- ============================================================================
-- 4) FUNÇÃO PARA INICIALIZAR ESTADO DO USUÁRIO
-- ============================================================================
-- Executada automaticamente quando um novo usuário é criado
-- Cria um registro vazio em user_state para esse usuário
-- Garante que o usuário tem um lugar para armazenar seus dados

create or replace function public.initialize_user_state()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.user_state (user_id, data)
  values (new.id, '{}'::jsonb)
  on conflict (user_id) do nothing;

  return new;
end;
$$;

-- Trigger: executado após novo usuário ser criado em auth.users
create trigger on_auth_user_initialize_state
  after insert on auth.users
  for each row
  execute procedure public.initialize_user_state();

-- ============================================================================
-- 5) ESTRUTURA DE DADOS DO JSON ARMAZENADO EM user_state.data
-- ============================================================================
-- Exemplo do JSON que será armazenado na coluna 'data':
--
-- {
--   "rounds": [
--     {
--       "id": "unique-id",
--       "name": "Round 1",
--       "score": 105,
--       "notes": "Good performance",
--       "timestamp": "2026-10-05T12:00:00.000Z"
--     }
--   ],
--   "analyses": [
--     "Análise detalhada do round 1"
--   ],
--   "timer": {
--     "elapsedSeconds": 0,
--     "isRunning": false
--   },
--   "settings": {
--     "theme": "light",
--     "lastUpdatedAt": "2026-10-05T12:00:00.000Z"
--   },
--   "history": [
--     "Ação 1: Round criado",
--     "Ação 2: Pontuação salva"
--   ],
--   "lastSyncedAt": "2026-10-05T12:00:00.000Z"
-- }

-- ============================================================================
-- 6) ÍNDICES PARA PERFORMANCE
-- ============================================================================
-- Índice em user_id para melhorar query de busca por usuário

create index if not exists idx_user_state_user_id on public.user_state(user_id);

-- ============================================================================
-- 7) NOTAS DE SEGURANÇA
-- ============================================================================
--
-- ✓ RLS ativado em todas as tabelas
-- ✓ Políticas garantem isolamento por auth.uid()
-- ✓ Cada usuário só acessa seus próprios dados
-- ✓ Triggers garantem sincronização automática
-- ✓ Sem segredos ou dados sensíveis no JSON
-- ✓ Cascade delete: remover user remove todos seus dados
--
-- Para testar se RLS está funcionando:
-- 1. Crie dois usuários diferentes
-- 2. Cada um faz login
-- 3. Tente na URL do browser:
--    SELECT * FROM user_state; -- deve retornar apenas o estado do usuário logado
--    SELECT * FROM profiles;   -- deve retornar apenas o perfil do usuário logado
