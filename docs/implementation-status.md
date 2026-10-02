# Status de implementação

Atualizado em 02/10/2026. O projeto está no fim da primeira entrega vertical. O P0 completo ainda não está concluído.

## Entregue e verificado

| Entrega / requisito | Estado | Evidência |
|---|---|---|
| E0 estrutura e ambiente | Concluído | Flutter, Spring Boot, PostgreSQL, Flyway, Compose, OpenAPI e ADR |
| RF-001 login/sessão | Parcial funcional | login, access token, refresh rotativo, logout e sessão web/mobile; convite e recuperação ainda pendentes |
| RF-002 tenant/equipe | Parcial funcional | duas academias isoladas e papel por unidade; gestão de convites/equipe pendente |
| RF-003 alunos/vínculos | Parcial funcional | cadastro, listagem, detalhe, pausa e cancelamento; responsável e reativação pendentes |
| RF-004 importação CSV | Backend funcional | prévia, erros, possíveis duplicatas, expiração e confirmação; tela Flutter pendente |
| RF-005 turmas/sessões | Fluxo principal funcional | criação e geração de quatro semanas, agenda e sessão concreta |
| RF-006 chamada manual | Fluxo principal funcional | roster, lote atômico, unicidade, versão e idempotência; QR e correções pendentes |
| RF-008 graduação | Parcial funcional | promoção exclusiva de owner, concorrência e histórico; configuração de faixas e correções pendentes |
| RF-009 pausas | Parcial funcional | pausa suspende alertas e término reativa; edição/interrupção antecipada pendente |
| Retenção V1 | Parcial funcional | elegibilidade, score, snapshot, alerta único, contato, retorno observado e encerramento |
| Flutter web/mobile | Primeira interface funcional | login, Hoje, Alunos, perfil, Agenda, chamada e Acompanhamento responsivos |

## Verificações executadas

- API Java compilada com Java 21 e Spring Boot 3.5.16.
- Migração Flyway executada em PostgreSQL 17.6.
- Login real e `/me` aprovados.
- Academia A consultando o ID da academia B recebeu 404.
- Dados sintéticos retornaram 30 alunos ativos e uma turma com 30 alunos.
- Avaliação de retenção criou 6 acompanhamentos a partir dos dados sintéticos.
- Chamada registrou 3 presenças; reenvio com a mesma chave retornou o mesmo resultado e permaneceu com 3 registros.
- Importação CSV validou 2 linhas, confirmou 2 alunos e repetiu a confirmação sem duplicá-los.
- `mvn test`: aprovado, incluindo exemplos e fronteiras do score.
- `flutter analyze`: sem problemas.
- `flutter test`: aprovado no layout compacto do login.
- `flutter build web --release`: aprovado.
- `flutter build apk --debug`: aprovado após atualizar `flutter_secure_storage` para 11.2.0; APK em `apps/tatame360_app/build/app/outputs/flutter-apk/app-debug.apk`.
- Revisão visual desktop do build web: aprovada em 1440×1000; login sem overflow, com foco e hierarquia claros. O layout compacto também possui teste de widget em 390×844.

## Próximas entregas do P0

1. Convites, recuperação de senha e gestão de equipe.
2. Interface de importação CSV e associação de turma no cadastro.
3. QR online, correção de presença e chamada offline persistente no mobile.
4. Responsáveis/dependentes e jornada do aluno.
5. Correção auditada de promoção e sistema de faixas configurável.
6. Avisos internos, preferências e adaptador de push não configurado.
7. Relatórios/exportação, assinatura SaaS manual, backup/restauração e observabilidade final.

## Limitações conhecidas

- O seed `dev` só deve ser usado localmente.
- O painel administrativo é a superfície testada; aluno e responsável ainda não possuem suas jornadas finais.
- O Flutter Web opera online; a fila offline é exclusiva do mobile e ainda será implementada.
- iOS não foi compilado neste ambiente Windows.
- Parâmetros do índice de engajamento são hipóteses do PRD e exigem calibração no piloto.
