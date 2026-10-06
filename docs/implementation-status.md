# Status de implementação

Atualizado em 06/10/2026. O Sprint 1 está concluído sobre a primeira entrega vertical. O P0 completo ainda não está concluído.

## Entregue e verificado

| Entrega / requisito | Estado | Evidência |
|---|---|---|
| E0 estrutura e ambiente | Concluído | Flutter, Spring Boot, PostgreSQL, Flyway, Compose, OpenAPI e ADR |
| RF-001 login/sessão | Fluxo principal funcional | login, access token, refresh rotativo, logout, recuperação com token único, troca de senha e revogação de sessões; entrega externa de e-mail pendente |
| RF-002 tenant/equipe | Parcial funcional | academias isoladas, convite único com expiração/revogação, aceite de conta nova ou existente, alteração de papel e desativação imediata; transferência de owner pendente |
| RF-003 alunos/vínculos | Parcial funcional | cadastro, listagem, detalhe, pausa e cancelamento; responsável e reativação pendentes |
| RF-004 importação CSV | Fluxo principal funcional | modelo UTF-8, upload Flutter, prévia por linha, duplicatas, confirmação idempotente e associação opcional à turma |
| RF-005 turmas/sessões | Fluxo principal funcional | criação e geração de quatro semanas, agenda e sessão concreta |
| RF-006 chamada manual | Fluxo principal funcional | roster, lote atômico, unicidade, versão e idempotência; QR e correções pendentes |
| RF-008 graduação | Parcial funcional | promoção exclusiva de owner, concorrência e histórico; configuração de faixas e correções pendentes |
| RF-009 pausas | Parcial funcional | pausa suspende alertas e término reativa; edição/interrupção antecipada pendente |
| Retenção V1 | Parcial funcional | elegibilidade, score, snapshot, alerta único, contato, retorno observado e encerramento |
| Flutter web/mobile | Primeira interface funcional | login, recuperação, convite, Hoje, Alunos, importação, perfil, Agenda, chamada, Acompanhamento e Equipe responsivos |

## Verificações executadas

- API Java compilada com Java 21 e Spring Boot 3.5.16.
- Migração Flyway executada em PostgreSQL 17.6.
- Login real e `/me` aprovados.
- Academia A consultando o ID da academia B recebeu 404.
- Dados sintéticos retornaram 30 alunos ativos e uma turma com 30 alunos.
- Avaliação de retenção criou 6 acompanhamentos a partir dos dados sintéticos.
- Chamada registrou 3 presenças; reenvio com a mesma chave retornou o mesmo resultado e permaneceu com 3 registros.
- Importação CSV validou 2 linhas, confirmou 2 alunos e repetiu a confirmação sem duplicá-los.
- Sprint 1 integrado: recuperação manteve resposta genérica, redefiniu a senha, revogou a sessão e permitiu novo login.
- Convite criou acesso na academia correta, recusou reutilização com HTTP 410 e a desativação retirou o acesso nas requisições seguintes.
- Importação pela nova API validou uma linha, associou turma e repetiu a confirmação sem criar outro aluno.
- `mvn test`: aprovado, incluindo exemplos e fronteiras do score.
- `flutter analyze`: sem problemas.
- `flutter test`: 3 testes aprovados, cobrindo login compacto e estados públicos de redefinição/convite.
- `flutter build web --release`: aprovado.
- `flutter build apk --debug`: aprovado após atualizar `flutter_secure_storage` para 11.2.0; APK em `apps/tatame360_app/build/app/outputs/flutter-apk/app-debug.apk`.
- Revisão visual desktop do build web: aprovada em 1440×1000; login sem overflow, com foco e hierarquia claros. O layout compacto também possui teste de widget em 390×844.

## Próximas entregas do P0

1. QR online, correção de presença e chamada offline persistente no mobile.
2. Responsáveis/dependentes, reativação e jornada do aluno.
3. Correção auditada de promoção e sistema de faixas configurável.
4. Avisos internos, preferências e adaptadores externos de e-mail/push.
5. Relatórios/exportação, assinatura SaaS manual, backup/restauração e observabilidade final.

## Limitações conhecidas

- O seed `dev` só deve ser usado localmente.
- O painel administrativo é a superfície testada; aluno e responsável ainda não possuem suas jornadas finais.
- O Flutter Web opera online; a fila offline é exclusiva do mobile e ainda será implementada.
- No perfil `dev`, o link de recuperação pode ser exibido na interface com `EXPOSE_ACCOUNT_TOKENS=true`; produção exige um adaptador de e-mail e deve manter essa opção desativada.
- iOS não foi compilado neste ambiente Windows.
- Parâmetros do índice de engajamento são hipóteses do PRD e exigem calibração no piloto.
