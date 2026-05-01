-- ============================================================
--  DO CHOPP — Fix 3 (definitivo) — adapta usuarios existente
-- ============================================================

-- 1. Adiciona colunas novas na tabela usuarios existente
alter table public.usuarios add column if not exists usuario       text;
alter table public.usuarios add column if not exists senha_hash    text;
alter table public.usuarios add column if not exists role          text;
alter table public.usuarios add column if not exists ultimo_acesso timestamptz;

-- Renomeia "perfil" para "role" se role ainda não existia
-- (já fizemos add column if not exists, então só sincroniza os dados)
update public.usuarios set role = perfil where role is null and perfil is not null;

-- 2. Unique em usuario (safe)
do $$ begin
  alter table public.usuarios add constraint usuarios_usuario_key unique (usuario);
exception when duplicate_object then null;
end $$;

-- 3. Insere usuários do sistema preenchendo TODAS as colunas NOT NULL
insert into public.usuarios (nome, senha, senha_hash, usuario, role, perfil, ativo)
select 'Administrador', 'admin123', 'admin123', 'admin', 'admin', 'admin', true
where not exists (select 1 from public.usuarios where usuario = 'admin');

insert into public.usuarios (nome, senha, senha_hash, usuario, role, perfil, ativo)
select 'Daniel', 'op123', 'op123', 'operador', 'operador', 'operador', true
where not exists (select 1 from public.usuarios where usuario = 'operador');

-- ============================================================
-- DEMAIS TABELAS (todas com IF NOT EXISTS)
-- ============================================================
create extension if not exists "uuid-ossp";

create table if not exists public.clientes (
  id uuid primary key default uuid_generate_v4(),
  tipo text, nome text not null, cpf_cnpj text,
  responsavel text, endereco text, numero text, bairro text,
  cep text, cidade text, estado text default 'SP',
  telefone text, whatsapp text, email text,
  segmento text, vendedor text default 'DANIEL',
  forma_pgto text, obs text, ativo boolean default true,
  created_at timestamptz default now()
);

create table if not exists public.fornecedores (
  id uuid primary key default uuid_generate_v4(),
  nome text not null, cnpj text, contato text,
  telefone text, email text, endereco text,
  forma_pgto text, prazo_dias integer default 0,
  status text default 'ativo', obs text,
  created_at timestamptz default now()
);

create table if not exists public.produtos (
  id uuid primary key default uuid_generate_v4(),
  codigo integer, nome text not null, litros integer,
  custo numeric(10,2) default 0,
  preco_festa numeric(10,2) default 0,
  preco_bar numeric(10,2) default 0,
  estoque_atual integer default 0,
  estoque_minimo integer default 2,
  fornecedor_id uuid references public.fornecedores(id),
  ativo boolean default true,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

create table if not exists public.orcamentos (
  id uuid primary key default uuid_generate_v4(),
  numero serial, cliente_id uuid references public.clientes(id),
  tipo_cliente text, vendedor text default 'DANIEL',
  data_emissao date default current_date, data_validade date,
  status text default 'em_aberto',
  frete numeric(10,2) default 0, desc_global numeric(5,2) default 0,
  subtotal numeric(10,2) default 0, total numeric(10,2) default 0,
  obs_entrega text, obs_interna text, created_by uuid,
  created_at timestamptz default now(), updated_at timestamptz default now()
);

create table if not exists public.orcamento_itens (
  id uuid primary key default uuid_generate_v4(),
  orcamento_id uuid not null references public.orcamentos(id) on delete cascade,
  produto_id uuid references public.produtos(id),
  descricao text, litros integer, qtde integer default 1,
  preco_unit numeric(10,2) default 0,
  desconto_perc numeric(5,3) default 0,
  total_item numeric(10,2) default 0
);

create table if not exists public.pedidos (
  id uuid primary key default uuid_generate_v4(),
  numero serial, orcamento_id uuid references public.orcamentos(id),
  cliente_id uuid references public.clientes(id),
  tipo_cliente text, vendedor text default 'DANIEL',
  data_emissao date default current_date, data_entrega date,
  status_pagto text default 'aberto', status_entrega text default 'pendente',
  forma_pgto text, valor_sinal numeric(10,2) default 0,
  frete numeric(10,2) default 0, adicional numeric(10,2) default 0,
  total numeric(10,2) default 0,
  end_entrega text, periodo_entrega text,
  obs_interna text, obs_evento text,
  baixa_estoque boolean default false, created_by uuid,
  created_at timestamptz default now(), updated_at timestamptz default now()
);

create table if not exists public.pedido_itens (
  id uuid primary key default uuid_generate_v4(),
  pedido_id uuid not null references public.pedidos(id) on delete cascade,
  produto_id uuid references public.produtos(id),
  descricao text, litros integer, qtde integer default 1,
  preco_unit numeric(10,2) default 0,
  desconto_perc numeric(5,3) default 0,
  total_item numeric(10,2) default 0
);

create table if not exists public.equipamentos (
  id uuid primary key default uuid_generate_v4(),
  descricao text not null, valor numeric(10,2) default 0,
  qtde_total integer default 1, qtde_rua integer default 0,
  ativo boolean default true, created_at timestamptz default now()
);

create table if not exists public.comodatos (
  id uuid primary key default uuid_generate_v4(),
  cliente_id uuid references public.clientes(id),
  cliente_nome text, equipamento_id uuid references public.equipamentos(id),
  kit_descricao text, qtde integer default 1,
  valor numeric(10,2) default 0,
  data_saida date default current_date, data_retorno date,
  status text default 'ativo', tipo_retorno text,
  quem_recolheu text, obs text, created_by uuid,
  created_at timestamptz default now()
);

create table if not exists public.gastos_fixos (
  id uuid primary key default uuid_generate_v4(),
  descricao text not null, tipo text,
  valor numeric(10,2) default 0, forma_pgto text,
  dia_vencimento integer, ativo boolean default true,
  obs text, created_at timestamptz default now()
);

create table if not exists public.estoque_movimentos (
  id uuid primary key default uuid_generate_v4(),
  produto_id uuid references public.produtos(id),
  pedido_id uuid references public.pedidos(id),
  tipo text, qtde integer,
  estoque_antes integer, estoque_depois integer,
  data_mov timestamptz default now(),
  obs text, usuario_id uuid
);

create table if not exists public.alertas (
  id uuid primary key default uuid_generate_v4(),
  tipo text, mensagem text, referencia_id uuid,
  referencia_tipo text, lido boolean default false,
  created_at timestamptz default now()
);

-- Indexes
create index if not exists idx_orcamentos_cliente on public.orcamentos(cliente_id);
create index if not exists idx_pedidos_cliente    on public.pedidos(cliente_id);
create index if not exists idx_pedidos_entrega    on public.pedidos(data_entrega);
create index if not exists idx_pedidos_status     on public.pedidos(status_pagto);
create index if not exists idx_estmov_produto     on public.estoque_movimentos(produto_id);
create index if not exists idx_comodatos_status   on public.comodatos(status);

-- Views
create or replace view public.estoque_disponivel as
  select p.id, p.nome, p.litros, p.estoque_atual,
    coalesce(sum(pi.qtde),0) as qtde_reservada,
    p.estoque_atual - coalesce(sum(pi.qtde),0) as qtde_disponivel,
    p.estoque_minimo
  from public.produtos p
  left join public.pedido_itens pi on pi.produto_id = p.id
  left join public.pedidos ped on ped.id = pi.pedido_id
    and ped.data_entrega >= current_date
    and ped.status_entrega = 'pendente'
  where p.ativo = true
  group by p.id, p.nome, p.litros, p.estoque_atual, p.estoque_minimo;

create or replace view public.equipamentos_view as
  select *, (qtde_total - qtde_rua) as qtde_disponivel from public.equipamentos;

-- Trigger: baixa de estoque
create or replace function public.fn_baixa_estoque_pedido()
returns trigger language plpgsql as $$
begin
  if NEW.status_entrega = 'entregue' and OLD.status_entrega != 'entregue' and NEW.baixa_estoque = false then
    update public.produtos p
    set estoque_atual = p.estoque_atual - pi.qtde, updated_at = now()
    from public.pedido_itens pi
    where pi.pedido_id = NEW.id and pi.produto_id = p.id;

    insert into public.estoque_movimentos (produto_id, pedido_id, tipo, qtde, obs)
    select produto_id, NEW.id, 'saida', qtde, 'Baixa automática — pedido #' || NEW.numero
    from public.pedido_itens where pedido_id = NEW.id;

    NEW.baixa_estoque = true;
  end if;
  return NEW;
end;
$$;
drop trigger if exists trg_baixa_estoque on public.pedidos;
create trigger trg_baixa_estoque
  before update on public.pedidos
  for each row execute function public.fn_baixa_estoque_pedido();

-- Trigger: orçamento aprovado → pedido
create or replace function public.fn_orcamento_vira_pedido()
returns trigger language plpgsql as $$
declare v_pedido_id uuid;
begin
  if NEW.status = 'aprovado' and OLD.status != 'aprovado' then
    insert into public.pedidos (orcamento_id, cliente_id, tipo_cliente, vendedor,
      data_emissao, frete, total, obs_interna)
    values (NEW.id, NEW.cliente_id, NEW.tipo_cliente, NEW.vendedor,
      NEW.data_emissao, NEW.frete, NEW.total, NEW.obs_interna)
    returning id into v_pedido_id;

    insert into public.pedido_itens
      (pedido_id, produto_id, descricao, litros, qtde, preco_unit, desconto_perc, total_item)
    select v_pedido_id, produto_id, descricao, litros, qtde, preco_unit, desconto_perc, total_item
    from public.orcamento_itens where orcamento_id = NEW.id;

    insert into public.alertas (tipo, mensagem, referencia_id, referencia_tipo)
    values ('orcamento_aprovado',
            'Orçamento #' || NEW.numero || ' aprovado — pedido criado automaticamente.',
            v_pedido_id, 'pedido');
  end if;
  return NEW;
end;
$$;
drop trigger if exists trg_orcamento_aprovado on public.orcamentos;
create trigger trg_orcamento_aprovado
  after update on public.orcamentos
  for each row execute function public.fn_orcamento_vira_pedido();

-- RLS
do $$ declare t text;
begin
  for t in select unnest(array[
    'usuarios','clientes','fornecedores','produtos','orcamentos','orcamento_itens',
    'pedidos','pedido_itens','equipamentos','comodatos',
    'gastos_fixos','estoque_movimentos','alertas'
  ]) loop
    execute 'alter table public.' || t || ' enable row level security';
    begin
      execute 'create policy "acesso_total" on public.' || t
           || ' for all using (true) with check (true)';
    exception when duplicate_object then null;
    end;
  end loop;
end $$;

-- Realtime
do $$ begin alter publication supabase_realtime add table public.pedidos;       exception when others then null; end $$;
do $$ begin alter publication supabase_realtime add table public.orcamentos;    exception when others then null; end $$;
do $$ begin alter publication supabase_realtime add table public.produtos;      exception when others then null; end $$;
do $$ begin alter publication supabase_realtime add table public.alertas;       exception when others then null; end $$;
do $$ begin alter publication supabase_realtime add table public.estoque_movimentos; exception when others then null; end $$;

-- ============================================================
select 'Setup Do Chopp concluído com sucesso! 🍺' as resultado;
