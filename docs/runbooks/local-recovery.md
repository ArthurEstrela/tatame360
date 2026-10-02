# Runbook local: banco e restauração

Este runbook cobre somente o ambiente de desenvolvimento. Não é uma política de produção.

## Verificar serviços

```powershell
docker compose --env-file .env -f infra/compose.yaml ps
curl.exe http://localhost:18080/actuator/health
```

## Backup local

Crie um diretório `backups` dentro do projeto e execute `pg_dump` no container, redirecionando o arquivo somente para esse diretório. Não inclua dumps no Git e não use dados reais no ambiente de demonstração.

## Restaurar

1. Pare a API para evitar novas gravações.
2. Crie um banco vazio com a mesma versão principal do PostgreSQL.
3. Restaure o dump.
4. Inicie a API e aguarde a validação/migração Flyway.
5. Confirme health check, academias, usuários, vínculos, sessões, presença e alertas.
6. Registre a data, origem do backup e resultado da restauração.

Uma restauração só é considerada testada depois de consultar um conjunto conhecido e validar os relacionamentos, não apenas quando o comando termina sem erro.
