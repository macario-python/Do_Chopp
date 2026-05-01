# 🍺 Do Chopp — Sistema de Gestão

Sistema web completo para gestão da **Do Chopp Distribuidora Ltda**.

## Stack
- **Frontend:** HTML + CSS + JavaScript (single file, sem framework)
- **Backend / Banco:** [Supabase](https://supabase.com) (PostgreSQL)
- **Realtime:** Supabase Realtime (WebSocket)

## Funcionalidades
- 🔐 Login com perfis Admin e Operador
- 📋 Orçamentos → aprovação automática vira Pedido
- 📦 Pedidos com status (Em Aberto / Pago Parcial / Pago)
- 🍺 Produtos com controle de estoque (Festa e Bar)
- 👥 Clientes (Festas e Bares)
- 🏭 Fornecedores com contato e endereço
- 🔧 Comodato — Estoque vs Na Rua com histórico
- 💰 Gastos Fixos com alertas de vencimento
- 📊 Dashboard com resumo em tempo real
- 🔔 Alertas automáticos (estoque baixo, contas a vencer)
- ⚡ Realtime — Admin e Operador sincronizados

## Configuração

### 1. Supabase
- Projeto: `estoque-granada`
- URL: `https://nmefykzbphcmktuhccf.supabase.co`
- Execute o SQL em `/sql/setup.sql` no SQL Editor do Supabase

### 2. Chave API
No arquivo `index.html`, a linha:
```javascript
const SUPABASE_KEY = 'SUA_PUBLISHABLE_KEY';
```

### 3. Rodar
Abra o `index.html` no navegador — sem servidor necessário.

## Logins padrão
| Usuário | Senha | Perfil |
|---|---|---|
| admin | admin123 | Admin (acesso total) |
| operador | op123 | Operador (acesso restrito) |

> ⚠️ Altere as senhas após o primeiro acesso.

## Estrutura
```
Do_Chopp/
├── index.html        ← sistema completo
├── sql/
│   └── setup.sql     ← cria todas as tabelas no Supabase
├── docs/
│   └── ...
└── README.md
```

## Próximos passos
- [ ] Hospedar em servidor (Netlify / Vercel / GitHub Pages)
- [ ] Autenticação via Supabase Auth
- [ ] Relatórios em PDF
- [ ] App mobile (PWA)
