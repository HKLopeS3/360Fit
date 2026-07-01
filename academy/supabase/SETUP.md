# 360Fit Academy — Configuração do Supabase

## 1. Criar o projeto

1. Acesse https://supabase.com/dashboard
2. Clique em **New project**
3. Nome: `360fit-academy`
4. Senha do banco: salve em local seguro
5. Região: `South America (São Paulo) — sa-east-1`
6. Clique em **Create new project** e aguarde ~2 min

## 2. Aplicar a migration 0001 (schema)

No Supabase Dashboard → **SQL Editor** → **New query**:

Cole o conteúdo de `migrations/0001_schema_inicial.sql` e clique **Run**.

## 3. Configurar o app Flutter

Copie a URL e a anon key do projeto:
Dashboard → **Project Settings** → **API**

Edite `.claude/launch.json` e adicione uma configuração:

```json
{
  "name": "academy-web-supabase",
  "runtimeExecutable": "C:\\dev\\flutter\\bin\\flutter.bat",
  "runtimeArgs": [
    "run", "-d", "web-server", "--release", "--web-port=8080",
    "--dart-define=SUPABASE_URL=https://XXXXX.supabase.co",
    "--dart-define=SUPABASE_ANON_KEY=sb_publishable_XXXXX"
  ],
  "cwd": "academy",
  "port": 8080
}
```

## 4. Criar conta gestor via app

Abra o app → tela de cadastro → preencha nome da academia e email/senha.
O trigger `on_auth_user_created_academy` criará automaticamente:
- 1 linha em `academias`
- 1 linha em `perfis` com papel `gestor`

## 5. Aplicar o seed de demonstração (opcional)

No SQL Editor, cole `migrations/0002_seed_demo.sql` e clique **Run**.
Isso cria 3 planos, 8 turmas, 4 alunos, contratos e check-ins de teste.

## Estrutura das tabelas

| Tabela         | Descrição                                  |
|----------------|--------------------------------------------|
| `academias`    | Cadastro da academia (1 por conta)         |
| `perfis`       | Usuários do painel: gestor/recepcionista   |
| `planos`       | Planos oferecidos pela academia            |
| `alunos`       | Alunos cadastrados                         |
| `contratos`    | Vínculo aluno ↔ plano com datas           |
| `mensalidades` | Cobranças (geradas pelo trigger)           |
| `turmas`       | Aulas/turmas agendadas                     |
| `inscricoes`   | Alunos inscritos em turmas                 |
| `checkins`     | Registro de entradas                       |

## Variáveis de ambiente

```
SUPABASE_URL=https://XXXXX.supabase.co
SUPABASE_ANON_KEY=sb_publishable_XXXXX
```
