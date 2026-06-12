# Deploy do 360Fit

Guia passo a passo para fazer deploy da aplicação.

## Arquitetura

```
360Fit (Netlify)
    ↓ (API calls)
Supabase Backend
    ├─ PostgreSQL (Banco de dados)
    ├─ Auth (Autenticação)
    ├─ Storage (Fotos, vídeos)
    └─ RLS (Row Level Security)
```

## Pré-requisitos

- ✅ Conta GitHub (com 360Fit criado)
- ✅ Projeto Supabase configurado
- ✅ Conta Netlify
- ✅ Flutter instalado localmente (para testes)

## Passo 1: Configurar Supabase

1. Acesse [supabase.com](https://supabase.com)
2. Crie um novo projeto ou use um existente
3. Em **Settings > API**, copie:
   - `Project URL` → `SUPABASE_URL`
   - `anon public key` → `SUPABASE_ANON_KEY`

4. Verifique as migrations:
   ```bash
   # No arquivo supabase/migrations/
   # Devem existir: 0001_schema.sql, 0002_rls.sql, etc
   ```

## Passo 2: Conectar GitHub a Netlify

1. Acesse [netlify.com](https://netlify.com)
2. Clique "Add new site" → "Connect to Git"
3. Selecione GitHub → Autorize
4. Selecione repository `HKLopeS3/360Fit`
5. Em Build settings:
   - Build command: `cd app && flutter build web`
   - Publish directory: `app/build/web`

## Passo 3: Configurar variáveis de ambiente

Na página do site no Netlify:

1. Vá em **Site settings > Build & deploy > Environment**
2. Clique "Edit variables"
3. Adicione:
   ```
   SUPABASE_URL = https://seu-project.supabase.co
   SUPABASE_ANON_KEY = sua-chave-anon
   DEMO_SENHA = demo360fit
   ```

## Passo 4: Deploy automático

Após configurar tudo:

```bash
# Faça um commit e push
git add .
git commit -m "Prepare for Netlify deployment"
git push origin main
```

Netlify automaticamente:
- ✅ Detecta mudanças
- ✅ Inicia build do Flutter para web
- ✅ Faz deploy

## Verificar após deploy

- [ ] Acesse o site em https://seu-site.netlify.app
- [ ] Teste login com usuário demo
- [ ] Verifique conexão ao Supabase nos Network Tabs
- [ ] Teste criar um aluno/treino

## Troubleshooting

### Build falha com "Flutter not found"

Netlify precisa instalar Flutter. Adicione ao `netlify.toml`:

```toml
[build.environment]
FLUTTER_VERSION = "3.24.0"
```

### Variáveis de ambiente não reconhecidas

Reinicie o deploy após adicionar variáveis:
- Vá em **Deploys > Trigger Deploy > Clear cache and redeploy**

### Erro 404 em rotas da SPA

Já configurado no `netlify.toml` com `_redirects`, mas verifique se arquivo existe:

```bash
echo '/* /index.html 200' > app/build/web/_redirects
```

### Conexão Supabase recusada

- Verifique se `SUPABASE_URL` e `SUPABASE_ANON_KEY` estão corretos
- Teste localmente: `flutter run -d web-server --dart-define=...`
- Verifique CORS no Supabase (Settings > API)

## Monitoramento

Após deploy, monitore:

1. **Logs de build**: Netlify Dashboard → Deploys → Show logs
2. **Erros de runtime**: Browser DevTools → Console
3. **Performance**: Netlify Analytics ou Google Lighthouse
4. **Banco de dados**: Supabase Dashboard → Logs

## CI/CD (Próxima fase)

Para automatizar testes antes de deploy, adicione:

```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
      - run: cd app && flutter test
  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - # Deploy automático via Netlify
```

## Rollback

Se algo der errado após deploy:

1. Vá em **Netlify > Deploys**
2. Encontre o último deployment estável
3. Clique os 3 pontos → "Publish deploy"

---

**Próximos passos:**
- [ ] Subir GitHub
- [ ] Conectar Netlify
- [ ] Configurar variáveis
- [ ] Fazer primeiro deploy
- [ ] Testar funcionalidades
- [ ] Monitorar por 24h
