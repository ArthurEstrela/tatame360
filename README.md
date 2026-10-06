# Tatame360

Primeira entrega vertical do SaaS para academias de Jiu-Jitsu. O repositório contém um aplicativo Flutter compartilhado entre web, Android e iOS, uma API Java 21/Spring Boot e PostgreSQL.

## O que funciona

- login com access token curto e refresh rotativo;
- recuperação de senha com token único e revogação das sessões anteriores;
- isolamento de dados por academia e unidade;
- convites, papéis e ativação/desativação da equipe;
- cadastro e consulta de alunos;
- importação CSV responsiva com modelo, prévia, duplicatas, turma e confirmação idempotente;
- criação de turmas e geração de sessões;
- chamada manual atômica e idempotente;
- graduação explícita por owner, com controle de versão;
- pausa e cancelamento com preservação de histórico;
- índice de engajamento explicável, alertas e contatos;
- painel Flutter responsivo para web e mobile.

Consulte [docs/implementation-status.md](docs/implementation-status.md) para o escopo validado e as pendências do P0.

## Requisitos locais

- Flutter 3.47.1 / Dart 3.13.1 ou versão compatível;
- Java 21;
- Maven 3.9+;
- Docker Desktop para PostgreSQL;
- Chrome/Edge para web ou Android SDK para mobile.

## Configuração

Na raiz do projeto, copie `infra/env.example` para `.env` e troque as duas senhas. O arquivo `.env` está ignorado pelo Git.

```powershell
Copy-Item infra/env.example .env
docker compose --env-file .env -f infra/compose.yaml up -d
```

Defina no terminal da API as variáveis presentes no `.env`. Depois execute:

```powershell
cd services/api
mvn spring-boot:run
```

A API usa `http://localhost:18080`. O perfil `dev` cria duas academias e contas sintéticas. A senha é o valor local de `DEMO_PASSWORD`; o usuário principal é `owner@raiz.example`. Nunca publique esse perfil nem essa credencial.

`EXPOSE_ACCOUNT_TOKENS=true` mostra o atalho de recuperação somente no ambiente local. Em produção, mantenha `false` e conecte o adaptador de e-mail transacional.

Em outro terminal:

```powershell
cd apps/tatame360_app
flutter run -d chrome --web-port 7357 --dart-define=API_URL=http://localhost:18080/api/v1
```

No emulador Android, use `http://10.0.2.2:18080/api/v1`. Em aparelho físico, informe o IP acessível da máquina de desenvolvimento e configure a política de rede apenas no ambiente local.

## Verificação

```powershell
cd services/api
mvn test

cd ../../apps/tatame360_app
flutter analyze
flutter test
flutter build web --release --dart-define=API_URL=http://localhost:18080/api/v1
flutter build apk --debug --dart-define=API_URL=http://10.0.2.2:18080/api/v1
```

O iOS precisa ser compilado e validado em macOS com Xcode.

## Estrutura

```text
apps/tatame360_app  Flutter web/mobile
services/api        API Spring Boot
contracts           OpenAPI
infra               PostgreSQL local
docs                PRD, decisões, status e runbooks
```

As dependências externas de push, e-mail e pagamentos ainda não fazem parte desta entrega. Convites são compartilhados por link; no ambiente local, a recuperação exibe um atalho explícito de teste.
