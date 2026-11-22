# Munny — Saldoup

MVP acadêmico de gerenciamento de finanças pessoais, desenvolvido com HTML, CSS, JavaScript e Supabase.

## Funcionalidades desta versão inicial

- Cadastro e login com Supabase Auth.
- Perfil e categorias padrão criados automaticamente no cadastro.
- Registro, edição, exclusão e listagem de receitas e despesas.
- Transações futuras com status `AGENDADA`.
- Painel com saldo, receitas, despesas e distribuição por categoria.
- Criação e acompanhamento de metas vinculadas a receitas.
- Row Level Security (RLS) para separar os dados dos usuários.

## 1. Criar o projeto Supabase

1. Acesse https://supabase.com e crie um projeto.
2. Abra **SQL Editor** e execute todo o conteúdo de `database/schema.sql`.
3. Em **Project Settings → API**, copie o Project URL e a chave `anon`/`publishable` pública.
4. Abra `js/supabase.js` e substitua os dois valores de configuração.
5. Em **Authentication → URL Configuration**, configure a URL local e, depois, a URL de publicação.
6. Para testar cadastro com confirmação de e-mail, configure SMTP ou use o fluxo de confirmação disponibilizado pelo Supabase. Em ambiente de demonstração, a confirmação pode ser ajustada nas configurações de Auth do projeto, conforme a política da equipe.

> Nunca coloque a chave `service_role` no frontend. A chave pública anon/publishable é usada com RLS habilitado.

## 2. Executar localmente

Como o projeto usa JavaScript no navegador e o SDK do Supabase via CDN, execute por um servidor HTTP local (não abra o arquivo diretamente por `file://`).

Com Python instalado, na pasta do projeto:

```bash
python -m http.server 8000
```

Acesse http://localhost:8000.

Também é possível usar a extensão **Live Server** do Visual Studio Code.

## 3. Estrutura

```text
munny/
├── index.html
├── css/style.css
├── js/supabase.js
├── js/app.js
├── database/schema.sql
└── README.md
```

## 4. Regras implementadas

- Valores de transações devem ser maiores que zero.
- Uma transação exige categoria do mesmo tipo (receita/despesa).
- Transações com data futura são gravadas como agendadas.
- O saldo considera somente transações efetivadas e com data até hoje.
- Metas recebem contribuições de transações do tipo receita vinculadas a elas.
- O progresso é recalculado após edição e exclusão de transações.
- O usuário só consulta e altera registros associados ao próprio `auth.uid()`.

## 5. Limitações e próximos incrementos

Esta é a base funcional inicial, ainda não uma versão publicada/validada. Antes da entrega acadêmica, testar todos os fluxos com duas contas diferentes, validar o processo de confirmação de e-mail, revisar mensagens de erro e testar agendamentos após a virada da data. A interface de categorias personalizadas e a recuperação de senha podem ser acrescentadas em uma próxima iteração.

## 6. Histórias de usuário

| História | Implementação inicial |
|---|---|
| US01 | Supabase Auth, `profiles`, políticas RLS |
| US02 | `transactions`, `categories`, formulário de movimentação |
| US03 | Painel, cálculo do saldo e agregação por categoria |
| US05 | Edição/exclusão de transações e recálculo |
| US04 | `goals`, progresso e conclusão de metas |
