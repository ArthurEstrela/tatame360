# Tatame360 — PRD de desenvolvimento

Versão: 1.1 · Data: 08/09/2026 · Idioma: português do Brasil.

Revisão 1.1: por decisão do usuário, aplicativo mobile e painel web serão implementados em Flutter, com uma base compartilhada. Esta decisão substitui a divisão de interfaces do plano mestre original.

Fonte: `Tatame360_Plano_Mestre_Produto.docx`, versão 1.0, e avaliação de viabilidade realizada nesta conversa. Este documento transforma a visão em requisitos implementáveis. Decisões adicionais são propostas de produto para a primeira implementação, sujeitas a validação no piloto; não representam resultados de pesquisa já obtidos.

## 1. Objetivo e proposta de valor

Construir uma plataforma de gestão e acompanhamento para academias de Jiu-Jitsu que permita identificar queda de frequência, organizar o contato humano e acompanhar o retorno dos alunos. A academia é o cliente pagante. Professores, equipe, alunos e responsáveis são usuários.

Promessa principal: “Saiba quem está deixando de treinar e organize o acompanhamento antes que esse aluno desapareça.”

O ciclo central é: cadastrar/importar → programar aula → registrar presença → identificar mudança de frequência → criar ação → registrar contato → acompanhar retorno.

O sistema apoia decisões do professor. Não concede graduação automaticamente, não diagnostica motivação ou saúde e não afirma que um retorno foi causado pelo software.

### 1.1 Problemas prioritários

1. Presenças dispersas em papel, planilhas e memória.
2. Quedas de frequência percebidas tarde.
3. Contatos sem responsável, prazo ou histórico.
4. Histórico de faixa e graus pouco confiável.
5. Implantação de software trabalhosa para o professor-dono.

### 1.2 Público inicial

Academias brasileiras com aproximadamente 40–250 alunos, uma unidade e professor-dono envolvido na operação. O piloto deve aceitar academias com gestão manual e academias que conservarão temporariamente outro sistema financeiro.

Não exigir CPF, instalação do aplicativo pelo aluno ou migração de pagamentos para registrar presenças e entregar o primeiro valor.

## 2. Escopo e estratégia de entrega

### 2.1 P0 — Piloto operacional

- Academia, unidade inicial, autenticação e permissões.
- Cadastro de alunos e responsáveis; importação CSV.
- Vínculos, pausas, cancelamentos e reativação.
- Grade, sessões e chamada manual no painel e no aplicativo do professor.
- Check-in por QR online e chamada manual offline no aplicativo.
- Histórico de faixa/graus e promoção humana auditada.
- Motor de atenção por regras, explicações e CRM de acompanhamento.
- Aplicativo do aluno com agenda, presenças e jornada básica.
- Avisos internos, preferências e notificações operacionais por push quando configuradas.
- Indicadores operacionais, auditoria, exportação e observabilidade.
- Operação de piloto pago com assinatura SaaS registrada manualmente pela plataforma.

### 2.2 P1 — Após validação do piloto

- Financeiro da academia: planos, cobranças, registro manual e integração com um PSP.
- Assinatura SaaS automatizada, distinta da cobrança dos alunos.
- Diário privado, metas pessoais e marcos de participação.
- Relatórios de coorte e acompanhamento de retorno mais completos.
- Automações de relacionamento revisáveis e IA para resumos/rascunhos.
- Fluxo de leads, aula experimental e matrícula pública.

### 2.3 P2 — Após uso recorrente e implantação repetível

- Múltiplas unidades na interface, redes e visão consolidada.
- Eventos, competições, currículo e certificados verificáveis.
- Outras modalidades, integrações e identidade portátil consentida.

### 2.4 Fora da primeira entrega

Rede social pública, marketplace, loja, transmissão de competições, white-label por academia, biometria, equipamentos físicos, machine learning preditivo, consultas arbitrárias por IA e graduação automática.

Projetar as referências de unidade e modalidade desde o início; não implementar interfaces ou infraestrutura de expansão apenas porque o modelo permite.

### 2.5 Ajustes deliberados em relação ao plano mestre

- Pilotar o fluxo central antes de completar todo o ecossistema.
- Incluir retenção na oferta inicial, pois ela é a proposta principal.
- Tratar o app do aluno como parte do P0 completo, mas permitir começar o piloto com chamada pelo professor enquanto a interface do aluno é concluída.
- Manter pagamentos de alunos fora do bloqueio do piloto e evitar duplicidade obrigatória de gestão financeira.
- Não fixar prazo de implementação antes de conhecer equipe, ambiente e capacidade.
- Usar Flutter tanto no mobile quanto no web, compartilhando código e adaptando a apresentação por tamanho de tela e forma de interação. A eventual troca de tecnologia web será uma decisão futura, não uma segunda implementação antecipada.

## 3. Sucesso e critérios de decisão

Metas propostas para avaliação, não evidências existentes:

| Indicador | Definição | Meta do piloto |
|---|---|---|
| Ativação da academia | Importou/cadastrou alunos, criou turma e concluiu primeira chamada | Mesmo dia da implantação |
| Tempo até primeira chamada | Entre início do onboarding assistido e primeira chamada concluída | Até 30 minutos com CSV válido e equipe presente |
| Velocidade da chamada | Marcar e revisar 30 alunos em sessão preparada | Menos de 2 minutos em teste de uso |
| Cobertura de chamada | Sessões realizadas com chamada finalizada / sessões realizadas | Pelo menos 80% |
| Ação em alertas | Alertas qualificados com contato registrado em até 7 dias / alertas qualificados com janela completa | Pelo menos 50% |
| Relevância | Alertas avaliados como úteis / alertas avaliados pelo professor | Pelo menos 60% |
| Rotina administrativa | Academias com uso semanal de chamada e acompanhamento | Pelo menos 4 de 5 no piloto ampliado |
| Disposição a pagar | Academias que pagaram, sem desconto permanente | Buscar 5 próximas de R$ 199/mês |
| Permanência comercial | Renovações dos clientes iniciais | Acompanhar por pelo menos 3 meses |

Registrar amostra e período junto às métricas. Separar observação de uso, resultado comercial e causalidade sobre evasão. Três a cinco academias não comprovam o efeito estatístico do produto sobre cancelamentos.

Avançar ao P1 quando houver uso semanal, ausência de falhas críticas de isolamento, onboarding repetível e pagamentos reais. Expandir aquisição somente após medir custo de implantação, suporte, aquisição e cancelamento das academias.

## 4. Papéis, escopos e autorização

Identidade de acesso e perfil de aluno são entidades diferentes. Um aluno pode existir sem conta. Uma pessoa pode ter múltiplos papéis, mas deve selecionar o contexto de academia e perfil de uso.

| Papel | Permissões principais | Restrições |
|---|---|---|
| Owner | Configurar academia, equipe, alunos, exportações, relatórios e graduação | Não acessar diário privado do aluno |
| Manager | Operação e relatórios dentro do escopo concedido | Não transferir propriedade nem elevar o próprio acesso |
| Instructor | Turmas atribuídas, chamada, perfis necessários, notas técnicas e CRM atribuído | Sem financeiro, exportação em massa ou promoção por padrão |
| FrontDesk | Cadastro, contatos operacionais, agenda e chamada nas unidades permitidas | Sem notas técnicas privadas e promoção |
| Student | Próprio perfil, agenda autorizada, check-in, histórico e jornada | Sem lista geral de alunos, notas internas ou score de atenção |
| Guardian | Dados operacionais dos dependentes vinculados e autorizados | Sem acesso a outros familiares ou diário privado |
| PlatformOperator | Provisionamento e suporte da plataforma | Sem acesso automático ao conteúdo das academias |

Capacidades explícitas adicionais: `progression.approve`, `members.export`, `billing.read`, `billing.write`, `team.manage`. Owner recebe as aplicáveis por padrão; delegação é auditada e não pode exceder a autoridade de quem delega.

Toda autorização combina usuário autenticado, vínculo ativo com a academia, unidade, capacidade e recurso. Esconder um botão não substitui checagem no servidor. Aluno ou responsável não pode obter notas internas por API, exportação, notificação ou mensagens de erro.

No P0, menores usam o fluxo de responsável. Conta independente de menor e diário para menor ficam desabilitados até existir política específica. Cadastro da criança não deve exigir e-mail próprio. Compartilhar telefone com o responsável é permitido.

## 5. Jornadas principais

### 5.1 Implantação

1. Operador provisiona convite de academia ou owner inicia cadastro habilitado para o piloto.
2. Owner verifica acesso, informa nome, unidade e fuso; padrão sugerido `America/Sao_Paulo`.
3. Configura equipe, faixas e horários básicos.
4. Importa CSV ou cadastra alunos manualmente.
5. Corrige erros na prévia sem criar registros parciais silenciosos.
6. Abre sessão, registra chamada e finaliza.
7. Visualiza confirmação de ativação; a retenção mostra “Coletando histórico” até cumprir elegibilidade.
8. Convida alunos/responsáveis sem impedir a operação de quem não aderir ao app.

### 5.2 Rotina do professor

Abrir Hoje → selecionar turma → registrar chamada → finalizar → consultar até 7 acompanhamentos prioritários → abrir contexto → registrar contato/resultado → definir próximo passo.

### 5.3 Rotina do aluno

Abrir Hoje → consultar próxima aula → realizar check-in online quando presente → conferir confirmação → consultar histórico e jornada. A API determina se a aula aceita check-in; relógio do celular não autoriza presença.

### 5.4 Acompanhamento

Queda de frequência qualificada → alerta único → responsável recebe tarefa → contato humano → resultado registrado → observação de novas presenças → encerramento com motivo e histórico.

Registrar contato não significa que o aluno voltou. Um novo treino não significa recuperação permanente.

## 6. Requisitos funcionais P0

### RF-001 — Autenticação e sessões

- Login por e-mail e senha, recuperação de acesso, convite de equipe e logout.
- Convites e redefinições com token de uso único, expiração e armazenamento seguro.
- Mensagem de recuperação não confirma se determinado e-mail existe.
- Sessões revogáveis; invalidar sessões pertinentes após troca de senha ou remoção de acesso.
- Access token curto e refresh com rotação e detecção de reutilização; política inicial: 15 minutos e até 30 dias, configuráveis.
- No navegador, refresh em cookie HttpOnly/Secure com política SameSite e proteção CSRF apropriadas; não armazenar refresh em localStorage.
- No mobile, segredos no armazenamento seguro do sistema.
- Aplicar limites a login, recuperação, convites e tentativas de token.
- Não permitir criação pública de papéis administrativos por manipulação do payload.

Aceite: um convite consumido ou expirado falha; logout revoga refresh; uma sessão da academia A não consulta recursos da B mesmo conhecendo o UUID.

### RF-002 — Academia e equipe

- Nome, nome de exibição, logo opcional, fuso, contato e unidade inicial.
- Convidar, alterar escopo e desativar equipe.
- Impedir remoção do último owner; transferência exige confirmação online e auditoria.
- Troca de academia limpa caches e estado de seleção.
- Configurações versionadas quando alteram resultados de retenção.

Aceite: professor removido perde autorização nas próximas requisições; dados da academia anterior não reaparecem ao trocar contexto.

### RF-003 — Cadastro e vínculos

- Campos: nome, nome social/exibição opcional, data de nascimento quando necessária, contato, modalidade, faixa/grau, início do vínculo e unidade.
- Campos opcionais: foto, turma principal, identificador externo de migração e observação administrativa restrita.
- Nome é obrigatório; e-mail, telefone e CPF não são identificadores universais de aluno.
- Perfil existe independentemente do estado de matrícula.
- Membership possui estados `ACTIVE`, `PAUSED`, `CANCELLED`; lead e experimental pertencem ao funil posterior, não à mesma enumeração financeira.
- Inadimplência futura é estado de cobrança, não cancelamento automático de matrícula.
- Cancelamento pede data efetiva e motivo categorizado opcional; não apaga histórico.
- Reativação cria novo episódio de vínculo para preservar coortes e cancelamentos anteriores.
- Evitar dois vínculos sobrepostos para a mesma modalidade e unidade no P0.
- Vínculo com responsável exige convite/confirmação verificável, sem associação automática apenas por telefone coincidente.

Aceite: dois irmãos com o mesmo telefone são cadastráveis; cancelar mantém presenças; reativação não altera a data do vínculo anterior.

### RF-004 — Importação CSV

- Template UTF-8 para download com instruções e dados fictícios.
- Aceitar delimitador vírgula ou ponto e vírgula; informar como datas serão interpretadas.
- Limite inicial: 5 MB e 5.000 linhas por lote, ambos configuráveis.
- Colunas mínimas: nome e data de início; permitir data padrão explícita para ausências de informação, registrando a origem estimada.
- Colunas opcionais: identificador externo, contato, data de nascimento, faixa, graus, turma e responsável.
- Processo: upload → mapeamento → validação → prévia → confirmação → relatório.
- Validar campos, datas futuras indevidas, graus incompatíveis e vínculos.
- Sugerir possíveis duplicatas; não mesclar pessoas automaticamente por nome, e-mail ou telefone.
- Por padrão, bloquear confirmação enquanto houver erros. Importação apenas das linhas válidas exige opção explícita e relatório de ignoradas.
- Confirmar lote de forma idempotente e transacional dentro do limite estabelecido.
- Permitir desfazer lote apenas quando registros não tiverem uso posterior; do contrário, explicar bloqueios por registro.
- Arquivos temporários têm expiração; valores exportados devem neutralizar fórmulas de planilha.

Aceite: confirmar duas vezes não duplica alunos; linha inválida tem número e motivo; duplicatas potenciais exigem decisão humana.

### RF-005 — Grade e sessões

- Turma recorrente com nome, dia, hora local, duração, modalidade, nível e instrutor.
- Sessão é uma ocorrência concreta com início/fim UTC e contexto de fuso.
- Gerar próximas 4 semanas de forma idempotente, com chave única para template e ocorrência.
- Alterar recorrência afeta somente ocorrências futuras selecionadas; não reescreve chamadas realizadas.
- Estados: `SCHEDULED`, `IN_PROGRESS`, `COMPLETED`, `CANCELLED`.
- Cancelamento avisa os interessados e preserva auditoria; sessões canceladas não entram na cobertura nem na frequência.
- Bloquear cancelamento com presenças válidas até correção explícita dos registros.
- Capacidade é informativa no P0; reservas e lista de espera pertencem a uma entrega futura.
- Na finalização, salvar o conjunto de alunos elegíveis usado na chamada para não recalcular ausências com matrículas posteriores.

Aceite: job repetido não duplica aulas; mudança de horário não altera histórico; feriado cancelado não conta como falta.

### RF-006 — Presença e check-in

- Chamada manual com busca, indicação de status e opção explícita “Marcar todos presentes”, seguida de revisão.
- Seleções são locais até confirmação; persistir lote atomicamente e retornar erros claros.
- Uma presença válida por aluno/sessão, garantida no banco.
- Registro contém origem `MANUAL`, `QR` ou `OFFLINE_SYNC`, autor, hora do servidor e identificador de operação.
- Presença pode ser invalidada com motivo e auditoria; não apagar a evidência histórica.
- QR identifica sessão/unidade com token assinado, expiração e nonce. Não contém dados pessoais.
- Token compartilhado pode ser usado por alunos distintos durante sua validade; impedir duplicidade por aluno/sessão, sem invalidar o QR após o primeiro aluno.
- Proposta inicial: rotação de 60 segundos; janela de check-in de 15 minutos antes do início até o fim da aula, configurável pela academia.
- Validar autenticação, vínculo, turma/unidade permitida, janela do servidor e assinatura.
- No P0, aluno pausado deve ser reativado por equipe autorizada antes de nova presença; interface oferece atalho para esse fluxo online.
- Scanner não salva presença offline. Professor usa chamada manual como alternativa.
- Sem localização, QR reduz atrito e algumas fraudes, mas não comprova fisicamente presença; não prometer essa garantia.
- Chamada reaberta para correção preserva versão e autor da finalização anterior.

Aceite: dois pedidos simultâneos produzem uma presença; QR expirado não registra; professor de outra unidade é bloqueado; correção atualiza agregados.

### RF-007 — Chamada offline seletiva

- Cache somente de sessões do dia, lista necessária e dados mínimos para operação autorizada.
- Fila persistente com UUID por operação, academia, usuário, sessão, aluno, versão conhecida e horário local informativo.
- Mostrar estados “Pendente de envio”, “Sincronizado” e “Precisa de revisão”.
- Servidor revalida sessão, permissão, vínculo e estado atual durante sincronização.
- Reenvio da mesma operação retorna resultado anterior.
- Inclusão repetida converge para presença única; invalidação/correção conflitante exige revisão, nunca sobrescrita silenciosa.
- Sessão cancelada, matrícula alterada ou permissão revogada gera conflito explícito.
- Nunca mostrar fila pendente como dado confirmado em relatório ou score.
- Logout/troca de academia com fila pendente avisa e exige sincronização ou descarte explícito. Cache é apagado ao concluir logout.
- Retomar app após encerramento do processo preserva a fila do mesmo usuário.

Aceite: uma chamada feita sem internet sobrevive ao reinício; reconexão não duplica; operação de usuário revogado é recusada; outro usuário não visualiza a fila.

### RF-008 — Graduação e jornada

- Sistema de faixas configurável por modalidade/faixa etária; dados iniciais são templates administrativos editáveis, não declaração de regra oficial vigente.
- Registrar nível inicial importado como baseline, distinguindo data conhecida de data estimada e sem inventar cerimônia.
- PromotionEvent contém nível anterior/novo, graus, data efetiva, aprovador e observação restrita opcional.
- Somente capacidade `progression.approve` pode confirmar, online.
- Confirmação apresenta aluno, nível anterior e novo para revisão.
- Corrigir por evento que referencia o anterior e o substitui; recalcular projeção atual sem apagar histórico.
- Duas promoções concorrentes usam controle de versão: uma é aceita e a outra exige atualização.
- Treinos e tempo de faixa são informação; não calculam “percentual merecido” ou concedem promoção.
- Revisão pode estar pendente, aprovada ou encerrada sem promoção.
- Jornada mostra início conhecido, presenças e promoções publicadas; notas internas ficam fora do payload do aluno.

Aceite: presença nunca promove; aluno não cria promoção pela API; correção mantém evidência e atualiza faixa atual consistentemente.

### RF-009 — Pausas

- Intervalo de datas locais inclusivas, motivo categorizado opcional e responsável pelo registro.
- Não solicitar detalhes clínicos; opção genérica “motivo pessoal” deve ser suficiente.
- Impedir intervalos sobrepostos no mesmo vínculo.
- Pausa suspende geração de alertas e tarefas automáticas de evasão no período.
- Ao iniciar pausa, tarefas abertas desse tipo ficam suspensas com motivo; contatos anteriores permanecem.
- No dia seguinte ao término, vínculo volta a ativo se não estiver cancelado e inicia janela de observação de 7 dias.
- Interrupção antecipada é explícita e auditada.
- Períodos sem aula por fechamento da unidade também devem impedir sinalização indevida; reiniciar elegibilidade conservadoramente quando contaminarem as janelas de comparação.

Aceite: aluno pausado não aparece como prioritário; cancelamento durante pausa impede reativação automática; término não dispara alerta baseado apenas na ausência durante a pausa.

## 7. Motor de retenção V1: especificação executável

### 7.1 Semântica

Usar “Índice de engajamento” de 0 a 100: maior significa menos necessidade de atenção segundo as regras. Não apresentar como probabilidade de cancelamento, avaliação técnica ou diagnóstico.

Estados separados do número: `INSUFFICIENT_DATA`, `PAUSED`, `OBSERVING`, `SCORED`, `CANCELLED`. Falta de dados retorna score nulo; nunca 100 por ausência de evidência.

### 7.2 Elegibilidade e qualidade de dados

Uma avaliação na data local D considera somente dias completos anteriores a D e presenças válidas em sessões realizadas.

- Vínculo ativo há pelo menos 28 dias, com janela de 28 dias observável desde início de coleta/importação confiável.
- Pelo menos 3 presenças nos 28 dias anteriores para estabelecer comparação mínima.
- Cobertura de chamada de pelo menos 80% nas sessões elegíveis da turma principal no período; se não houver turma principal, usar turmas explicitamente vinculadas. O denominador inclui todas as sessões previstas cujo fim já passou e que não foram canceladas, inclusive aquelas ainda não finalizadas; o numerador inclui apenas chamadas finalizadas. Sem vínculo de turma confiável, não gerar score comparativo.
- Denominador zero de sessões retorna “Sem aulas suficientes”.
- Pausa ou fechamento da unidade na janela comparativa suprime score V1 até haver 28 dias novamente observáveis. Os primeiros 7 dias após retorno são de observação; depois disso, enquanto não completar os 28 dias, mostrar dados insuficientes para comparação e permitir acompanhamento humano. É uma decisão conservadora para reduzir falsos alertas.
- Histórico importado de presença só é confiável para cobertura se incluir informação de sessões e chamada concluída; mera lista de check-ins não prova ausência.
- Não usar abertura de push, diário ou informações financeiras no score P0.

Alunos novos usam playbook separado: após 7 dias completos de vínculo, zero presenças e pelo menos duas sessões elegíveis com chamada finalizada, criar acompanhamento de acolhimento sem score. Respeitar pausa e evitar duplicidade.

### 7.3 Cálculo proposto

Janelas sem sobreposição: `recent = [D-7, D)` e `baseline = [D-28, D-7)`, usando datas locais convertidas em intervalos UTC.

```text
recentCount = presenças válidas em recent
baselineCount = presenças válidas em baseline
baselineWeekly = baselineCount / 3
daysSinceAttendance = dias locais desde a última presença válida antes de D

recencyPenalty:
  0..6 dias = 0
  7..13 dias = 15
  14..20 dias = 30
  21+ dias = 45

se baselineWeekly < 1:
  dropPenalty = 0
  fator de queda = "Base insuficiente para comparar queda"
senão:
  dropRatio = max(0, 1 - recentCount / baselineWeekly)
  queda < 25% = 0
  25% <= queda < 50% = 10
  50% <= queda < 75% = 20
  queda >= 75% = 35

inactiveWeeks = blocos completos [D-7,D), [D-14,D-7)
                sem presença e com sessões elegíveis observadas
regularityPenalty = 10 * inactiveWeeks

score = clamp(100 - recencyPenalty - dropPenalty - regularityPenalty, 0, 100)
```

Faixas: 80–100 saudável; 60–79 observar; 40–59 atenção; 0–39 atenção prioritária. Os sinais são correlacionados e os pesos são heurísticos; calibrar utilidade no piloto sem apresentá-los como validação científica.

Exemplo de teste: baseline com 9 presenças, semana recente com 1, última presença há 3 dias e uma das duas semanas sem treino → queda de aproximadamente 66,7%, penalidades 0 + 20 + 10 → score 70.

Outro caso: baseline com 9 presenças, semana recente sem treino, última presença há 10 dias e somente a semana recente vazia → 15 + 35 + 10 → score 40.

### 7.4 Execução e snapshots

- Job diário após 03h no fuso da unidade, com controle idempotente por academia/aluno/data/versão de regra.
- Configurações versionadas: pesos, limites e período de observação. Mudanças não reescrevem snapshots antigos.
- Snapshot guarda janelas, contagens, cobertura, fatores, score, versão e horário do processamento.
- Presença nova atualiza imediatamente o acompanhamento de retorno; score diário usa dias completos.
- Correção retroativa invalida agregados afetados e cria revisão de snapshot, preservando o anterior para auditoria.
- Falha do job mostra data da última atualização; não apresentar informação antiga como atual.

### 7.5 Alertas e ciclo de vida

- Score menor que 60 cria ou atualiza alerta; score de 60–79 aparece em observação sem tarefa automática.
- No máximo um alerta aberto do mesmo tipo por aluno/vínculo.
- Estados: `OPEN`, `IN_PROGRESS`, `SNOOZED`, `RETURN_OBSERVED`, `CLOSED`.
- Manter urgência e status operacional separados.
- Tarefa inicial vence em 2 dias corridos; permite ajuste pela equipe e usa calendário/fuso local.
- Adiar exige data de revisão. “Não relevante” exige categoria para medir falsos positivos.
- Nova presença após abertura produz `RETURN_OBSERVED`; registrar separadamente se houve contato anterior ao retorno.
- Encerramento exige decisão humana e motivo: retomada acompanhada, pausa, cancelamento, não relevante ou outro.
- Depois de encerrado, aplicar 7 dias de intervalo antes de novo alerta do mesmo tipo, exceto alteração manual documentada.
- Pausa suspende tarefa e impede nova geração; cancelamento fecha alerta como cancelamento, nunca como recuperação.

Cada card deve mostrar motivo factual, última presença, comparação disponível, confiabilidade dos dados, responsável, último contato e próxima ação. Exemplo: “Nenhum treino nos últimos 7 dias; média anterior de 3 por semana. Última presença há 10 dias.”

Aceite: execução repetida não duplica tarefa; matrícula sem dados recebe score nulo; score 59 gera atenção e score 60 não cria tarefa; retorno sem contato não conta como retorno após ação.

## 8. CRM e comunicação

### RF-010 — Tarefas e contatos

- Tarefa com aluno, alerta opcional, responsável, prazo, prioridade e status.
- Status da tarefa: aberta, em andamento, concluída, cancelada ou suspensa.
- Contato com canal, data efetiva, autor, resultado categorizado e observação curta.
- Resultados: sem resposta, conversou, dificuldade de horário, pretende voltar, pediu pausa, pediu cancelamento, outro.
- Pedido de pausa/cancelamento não altera matrícula sem confirmação explícita no fluxo próprio.
- Criar próximo contato é ação opcional, sem cadência infinita automática.
- Texto sugerido no P0 usa template determinístico editável.
- Abrir WhatsApp com texto é iniciativa do usuário; clicar não marca mensagem como enviada nem contato concluído.
- Não enviar mensagens externas automaticamente no piloto.
- Suprimir duplicatas quando dois professores tentarem assumir/concluir a mesma tarefa; usar versão otimista.

Aceite: só um responsável atual por tarefa; conclusão fica auditada; clique em canal externo sem confirmação não melhora métrica de ação.

### RF-011 — Avisos e notificações

- Avisos internos de alteração de aula e comunicações operacionais.
- Caixa de notificações funciona mesmo sem credenciais de push.
- Preferências por categoria, horários silenciosos e revogação de dispositivo.
- Payload mínimo em tela bloqueada; não incluir score, ausência detalhada, inadimplência ou notas privadas.
- Deep link autentica e revalida permissão antes de abrir o recurso.
- Evento persistido via outbox; retries com limite e backoff; registrar aceite pelo provedor separado de entrega/leitura confirmada.
- Na ausência de provedor configurado, mostrar integração não configurada; nunca registrar envio real fictício.

## 9. Telas e experiência

### 9.1 Direção visual

Interface sóbria, clara e rápida para uso durante aulas. Tema claro inicial, texto em grafite, superfícies neutras e uma cor principal de ação. Cores de faixas pertencem ao domínio e não substituem estados de interface. Usar ícones com rótulos em ações importantes.

Criar tokens de cor, tipografia, espaçamento, raio e elevação. Proposta: escala de espaço 4/8/12/16/24/32; texto base 16; controles de toque com pelo menos 44 px no web ou 48 dp no app. Contraste e leitura por leitor de tela devem ser verificados. Não depender apenas de cor para indicar risco.

### 9.2 Painel web

Navegação P0: Hoje, Alunos, Agenda, Acompanhamento, Graduações, Relatórios e Configurações. Financeiro só aparece quando entregue e habilitado.

| Tela | Conteúdo e ações | Estados especiais |
|---|---|---|
| Acesso | Login, recuperação, convite | Token expirado, credenciais inválidas, limite de tentativas |
| Onboarding | Academia, importação, turma e primeira chamada | Etapa salva, erros por linha, retomada |
| Hoje | Sessões do dia, até 7 prioridades, tarefas vencidas e retornos | Sem aula, coletando histórico, dados desatualizados |
| Alunos | Busca paginada, status, turma e faixa; cadastrar/importar | Nenhum resultado, importação em processamento |
| Perfil do aluno | Resumo, frequência, vínculo, jornada e acompanhamento | Pausa, cancelamento, restrição de aba por papel |
| Agenda | Semana e lista por dia; criar/editar/cancelar sessão | Feriado, conflito, mudança em recorrência |
| Chamada | Lista, busca, marcação e revisão | Presença duplicada, alteração concorrente, sessão cancelada |
| Acompanhamento | Lista por urgência, responsável, prazo e status | Sem alertas e sem dados são estados diferentes |
| Detalhe de alerta | Explicação, frequências, contatos e próxima ação | Pausa, retorno observado, encerrado |
| Graduações | Revisões, histórico e confirmação | Sem permissão, conflito de versão, correção |
| Relatórios | Cobertura, frequência e ações; exportação autorizada | Denominador zero, período incompleto |
| Configurações | Equipe, faixas, unidade, retenção e preferências | Mudança de regra versionada, último owner |

Perfil administrativo: abas Resumo, Presenças, Graduação, Acompanhamento e Cadastro. Notas internas são separadas por permissão; não enviar campos proibidos apenas para escondê-los visualmente.

### 9.3 Aplicativo Flutter

Modo professor: Hoje, Agenda, Acompanhamento e Perfil. Chamada acessível em até duas ações após abrir Hoje. Indicação persistente da conexão e da quantidade de operações pendentes.

Modo aluno: Hoje, Treinos, Jornada e Perfil. Mostrar próxima aula, check-in, presenças recentes, faixa/graus e avisos. Não exibir barra de merecimento de faixa.

Modo responsável: seletor explícito de dependente; agenda e histórico do dependente selecionado. Confirmar nome do dependente antes de ações. Presença de menor é registrada pela equipe no P0.

### 9.4 Estados obrigatórios em toda tela de dados

Carregando, vazio real, erro recuperável, sem permissão, offline quando aplicável e sucesso. Erros preservam entradas do formulário. Botões em processamento impedem repetição visual, enquanto servidor também garante idempotência.

Datas no fuso da academia; dinheiro em BRL quando habilitado. Não expor enums, stack traces ou nomes internos de tabelas aos usuários. Textos devem indicar a próxima ação: “Não foi possível enviar a chamada. Os registros continuam salvos neste aparelho.”

## 10. Arquitetura proposta

Stack definida pelo usuário: Flutter/Dart para Android, iOS e painel web; Java 21/Spring Boot no backend e PostgreSQL. Usar um projeto Flutter compartilhado, com navegação e layouts adaptados ao dispositivo e ao papel. Na implementação, verificar compatibilidade e fixar versões suportadas; este PRD não declara quais são as versões mais recentes.

- Backend como monólito modular: identity, academy, members, classes, attendance, progression, retention, crm, notifications, analytics e audit.
- Ports & adapters nos pontos de integração; evitar abstrações sem caso concreto.
- REST JSON com OpenAPI; contratos compartilhados ou clientes gerados para reduzir divergência.
- Migrações de banco versionadas; datas em UTC com fuso de negócio preservado e datas civis em campos de data.
- UUID para recursos; valores monetários futuros em centavos ou decimal de precisão definida, nunca ponto flutuante.
- Jobs/outbox inicialmente em PostgreSQL com locks e retries; Redis apenas se surgir necessidade mensurável.
- Armazenamento de objetos compatível com S3 para arquivos privados; ambiente local pode usar serviço equivalente em container.
- Flutter compartilhado: Riverpod para estado, GoRouter para rotas, cliente HTTP centralizado, modelos tipados, validação e componentes acessíveis; regras de negócio continuam no backend.
- Persistência mobile: Drift para cache/fila offline. Isolar armazenamento, autenticação, câmera, arquivos e notificações em adapters por plataforma, confirmando compatibilidade antes de instalar dependências.
- Web: painel Flutter com tabelas, filtros, paginação, teclado, foco, mouse, rolagem e layouts amplos. Mobile: listas e navegação compactas com controles de toque. Não apenas esticar a tela de celular.
- Compartilhar modelos, acesso à API, estado e componentes quando fizer sentido; permitir composições distintas para tarefas administrativas e rotina mobile.
- No P0, chamada offline persistente é requisito do aplicativo mobile. O painel web registra chamada online e informa indisponibilidade de conexão; não prometer fila offline no navegador sem implementação e validação específicas.
- Preservar políticas de sessão próprias de cada plataforma: cookie protegido no navegador e armazenamento seguro no mobile, conforme RF-001. Não portar armazenamento de tokens do mobile diretamente para o web.
- Navegação web deve suportar URLs diretas, recarregamento e voltar/avançar do navegador; configurar o hosting para resolver rotas do aplicativo. Validar permissões ao abrir cada rota.
- Entregar build web estático e builds mobile do mesmo projeto; configurações de ambiente separadas, sem segredos compilados no cliente. Uma mudança futura do frontend deve poder reutilizar os contratos da API.
- Nenhuma dependência de Figma é necessária para desenvolver a primeira interface.

### 10.1 Estrutura sugerida

```text
tatame360/
  apps/
    tatame360_app/
      lib/
        core/
        features/
        shared/
      android/
      ios/
      web/
      test/
      integration_test/
  services/
    api/
  contracts/
    openapi.yaml
  infra/
    compose.yaml
    env.example
  docs/
    prd.md
    architecture.md
    decisions/
    implementation-status.md
    runbooks/
  README.md
```

Se já existir repositório com estrutura válida, adaptar sem reescrita arbitrária. Não armazenar segredos nem dados reais nos exemplos.

## 11. Modelo de dados e invariantes

Todas as entidades de academia carregam `tenant_id`; as de unidade também `unit_id`. Referências cruzadas devem validar a mesma academia e, quando aplicável, usar chaves estrangeiras compostas. Índices devem refletir acesso por tenant e período.

| Entidade | Campos e responsabilidade principais |
|---|---|
| User | Identidade global autenticável, credencial, verificação e estado |
| Academy / AcademyUnit | Tenant, unidade, fuso e configuração |
| RoleAssignment | Usuário, tenant, unidade opcional, papel e capacidades |
| StudentProfile | Identidade local do aluno, contato mínimo e ligação opcional ao User |
| GuardianRelationship | Responsável, aluno, escopo, origem da verificação e revogação |
| Membership | Aluno, unidade, modalidade, início, fim e estado do episódio |
| MembershipEvent | Transições, datas efetivas, autor e motivo |
| PausePeriod | Vínculo, datas, motivo categorizado e término antecipado |
| ClassTemplate / ClassSession | Recorrência e ocorrência concreta |
| StudentClassAssignment | Elegibilidade de aluno em turmas com vigência |
| SessionRoster | Alunos elegíveis na finalização e estado da chamada |
| Attendance / AttendanceRevision | Presença única, origem, validade e correções |
| BeltSystem / BeltLevel | Níveis configuráveis, ordem e graus permitidos |
| ProgressReview / PromotionEvent | Revisão, decisão humana e histórico de graduação |
| RetentionRuleVersion | Parâmetros e vigência |
| RetentionSnapshot | Cálculo, janelas, qualidade e revisões |
| RetentionAlert | Tipo, vínculo, urgência, estado e resolução |
| RelationshipTask / ContactEvent | Responsável, prazo, ações e resultados |
| ImportBatch / ImportRow | Validação, decisão de duplicata, execução e relatório |
| Notification / DeviceRegistration | Aviso interno, destino e estado por canal |
| OutboxEvent / ProcessedEvent | Entrega assíncrona e deduplicação |
| IdempotencyRecord | Tenant, usuário, operação, chave, hash do payload e resposta |
| AuditEvent | Autor, recurso, ação, horário e alterações mínimas |
| AcademySubscription | Assinatura do SaaS, plano, vigência e estado comercial |

Não implementar tabelas P1 apenas para completar catálogo. Financeiro, diário e eventos serão introduzidos com suas migrações quando a etapa for executada.

Invariantes:

- Unique `(tenant_id, student_id, session_id)` para a presença lógica.
- Alerta aberto único por vínculo/tipo, com índice parcial ou restrição equivalente.
- Mesma chave de idempotência com payload diferente retorna conflito.
- Histórico de graduação é append-only na operação normal, com correção referenciada.
- Auditoria não armazena senhas, tokens, texto integral de diário ou dados excessivos.
- Soft delete não equivale a atender pedido de exclusão; anonimização e retenção têm fluxo próprio.
- Remover vínculo de acesso não apaga a pessoa nem libera seus dados a outro usuário.

## 12. API e contratos

Prefixo `/api/v1`. Contexto explícito por `/academies/{academyId}` nos recursos de academia. O identificador da rota é sempre validado contra a sessão; jamais é considerado autorização por si só.

| Método e rota relativa | Uso |
|---|---|
| POST `/auth/login`, `/auth/refresh`, `/auth/logout` | Sessões |
| POST `/auth/password-reset/request`, `/auth/password-reset/confirm` | Recuperação |
| GET `/me` | Identidade, academias e permissões |
| GET/POST `/academies/{a}/students` | Busca paginada e cadastro |
| GET/PATCH `/academies/{a}/students/{s}` | Perfil autorizado e edição |
| POST `/academies/{a}/imports/preview` | Validação e lote preliminar |
| POST `/academies/{a}/imports/{id}/confirm` | Confirmação idempotente |
| POST `/academies/{a}/memberships/{m}/pauses` | Pausa |
| POST `/academies/{a}/memberships/{m}/cancel` | Cancelamento |
| POST `/academies/{a}/students/{s}/memberships` | Novo vínculo/reativação |
| GET/POST `/academies/{a}/class-templates` | Grade |
| GET `/academies/{a}/sessions?from=&to=` | Ocorrências |
| POST `/academies/{a}/sessions/{id}/attendance/batch` | Chamada atômica |
| POST `/academies/{a}/sessions/{id}/check-in` | QR online |
| POST `/academies/{a}/attendance/sync` | Fila mobile, resultados por operação |
| POST `/academies/{a}/attendance/{id}/corrections` | Correção auditada |
| POST `/academies/{a}/sessions/{id}/complete` | Finalizar chamada |
| GET `/academies/{a}/students/{s}/journey` | Jornada autorizada |
| POST `/academies/{a}/students/{s}/progress-reviews` | Revisão |
| POST `/academies/{a}/students/{s}/promotions` | Promoção explícita |
| GET `/academies/{a}/retention/attention` | Fila paginada |
| GET `/academies/{a}/students/{s}/retention` | Explicação interna |
| POST/PATCH `/academies/{a}/crm/tasks[/{id}]` | Tarefa |
| POST `/academies/{a}/crm/tasks/{id}/contacts` | Contato |
| POST `/academies/{a}/crm/tasks/{id}/complete` | Conclusão |
| GET `/academies/{a}/analytics/overview` | Indicadores |
| GET `/academies/{a}/notifications` | Caixa interna |

Definir os endpoints auxiliares de edição, cancelamento, preferências e convites no OpenAPI antes de implementar cada fluxo. Colchetes na tabela são abreviação documental, não rota literal.

Paginação padrão de 25, máximo 100; ordenação estável com desempate por ID. Limitar intervalo de consultas e exportações. Não retornar entidades ORM diretamente.

Erro padrão:

```json
{
  "code": "ATTENDANCE_SESSION_CANCELLED",
  "message": "Esta aula foi cancelada. Revise a chamada antes de reenviar.",
  "fieldErrors": [],
  "requestId": "uuid"
}
```

HTTP: 400 formato inválido; 401 sem autenticação; 403 capacidade insuficiente; 404 recurso inexistente ou de outro tenant; 409 conflito; 422 regra de negócio; 429 limite de tentativas. Não revelar existência de recursos de outra academia.

Usar `Idempotency-Key` nas mutações repetíveis, importações e sincronização. Preservar resultado por pelo menos 30 dias no P0; restrições de domínio continuam impedindo duplicação após expiração. `version`/ETag protege alterações concorrentes.

Eventos essenciais: StudentEnrolled, StudentPaused, StudentCancelled, AttendanceRecorded, AttendanceCorrected, PromotionGranted, RetentionAlertOpened, ContactRecorded, ReturnObserved e NotificationRequested. Gravar domínio e outbox na mesma transação; consumidor deve tolerar entrega repetida.

## 13. Segurança, privacidade e operação

Estes são requisitos de engenharia e decisões de produto; não uma certificação de conformidade jurídica.

- TLS em produção, hashing forte de senha e segredos fora do código.
- Verificação server-side em leitura, escrita, busca, exportação, arquivos e jobs.
- Usuário de banco de produção com menor privilégio; não usar credencial de administrador na aplicação.
- Validação de uploads, tamanho limitado, nomes internos gerados e acesso assinado de curta duração.
- Backups protegidos e restauração testada; logs sem dados pessoais desnecessários.
- Ambiente de demonstração com dados sintéticos, sem cópia automática de produção.
- Operador da plataforma sem endpoint de impersonação no P0. Qualquer acesso excepcional futuro precisa de escopo, autorização e auditoria próprios.
- Instrumentação não envia nome, e-mail, telefone ou observação livre como propriedade analítica.
- Permitir solicitar exportação, correção e exclusão; registrar acompanhamento administrativo até conclusão.
- Definir antes da produção matriz de retenção por cadastro, financeiro, auditoria, importação e backups, conforme finalidade e obrigações aplicáveis.
- Proposta técnica inicial: CSV bruto temporário por até 7 dias; logs operacionais por 30 dias; backups diários por 30 dias. Prazos definitivos exigem validação de necessidade, contrato e operação.
- Fotos de menores e perfis públicos desabilitados por padrão; não implementar publicidade comportamental.
- Revogar convites, dispositivos e vínculos de responsáveis quando necessário.
- Separar dados do diário futuro do acesso administrativo comum; owner não tem direito automático de leitura.

### 13.1 Metas não funcionais

| Área | Meta proposta e verificação |
|---|---|
| Disponibilidade | 99,5% mensal como objetivo do piloto, medido após produção |
| API | P95 abaixo de 500 ms nas leituras comuns, sem chamadas a terceiros |
| Carga de referência | 100 academias sintéticas, 250 alunos por academia e 50 usuários concorrentes; registrar hardware e dataset |
| Isolamento | Nenhum acesso cruzado nos testes de matriz e nos fluxos críticos |
| Backup | RPO de até 24 horas e RTO de até 8 horas como objetivos iniciais, comprovados em simulação |
| Acessibilidade | Teclado no web, rótulos, foco visível, leitor de tela nos fluxos essenciais e contraste verificado |
| Falhas externas | Push e integrações indisponíveis não bloqueiam chamada manual online |
| Observabilidade | Request ID, latência, erros, jobs atrasados, fila/outbox e falhas de sincronização |

Escolher navegadores e versões mínimas de Android/iOS conforme suporte das dependências e aparelhos do piloto. Documentar a matriz real, sem prometer compatibilidade não testada.

## 14. Métricas e relatórios

- Academia ativada: primeira sessão concluída com pelo menos uma presença válida após cadastro de turma e alunos.
- Cobertura: sessões com chamada finalizada / sessões previstas cujo fim já passou, excluindo canceladas. Sessões ainda não finalizadas permanecem no denominador e aparecem como pendentes de classificação; não presumir ausência individual quando falta a chamada.
- Frequência semanal: presenças válidas por aluno em sessões distintas; múltiplos treinos no dia são possíveis.
- Ativos: vínculos ACTIVE na data de corte; pausados apresentados separadamente.
- Retenção D90: episódios de matrícula da coorte que não foram cancelados até o dia 90 / episódios que já completaram 90 dias; pausados contam como não cancelados, com quantidade indicada à parte.
- Cancelamento mensal de alunos: vínculos que estavam não cancelados no início e cancelaram no mês / vínculos não cancelados no início. Novos que cancelaram no próprio mês aparecem em indicador separado.
- Ação: contato efetivamente registrado; abrir card ou WhatsApp não conta.
- Retorno após contato: presença válida em até 14 dias após primeiro contato do alerta, com vínculo temporal; mostrar somente alertas com janela completa no percentual principal.
- Retorno sem contato: categoria separada.
- Recuperação sustentada: não publicar no P0; precisa de definição longitudinal e validação.
- MRR da plataforma: assinatura recorrente das academias; não somar mensalidades dos alunos ou taxas de implantação.

Eventos analíticos: onboarding_started, import_confirmed, first_attendance_completed, attendance_session_completed, attention_viewed, contact_recorded, return_observed, journey_viewed e subscription_renewed. Usar IDs internos, tenant, contexto, timestamp e versão; não incluir conteúdo privado.

## 15. Monetização e validação comercial

Hipótese inicial: plano piloto de aproximadamente R$ 199 por unidade/mês com presença, graduação e acompanhamento. Preço não deve ser hardcoded em regras centrais. Permitir override comercial auditado para piloto.

No P0, o operador registra cobrança externa e vigência da assinatura da academia manualmente. Não inserir checkout fictício. Trial sugerido de 30 dias; término sem contratação passa a leitura/exportação por 30 dias antes de arquivamento segundo política contratual, sem apagar automaticamente dados.

Separar claramente:

1. Assinatura da academia para usar Tatame360.
2. Cobranças da academia para seus alunos, implementadas no P1.

Medir receita, tributos/taxas reais, infraestrutura, tempo de suporte, implantação, CAC e pró-labore. Não exibir margem fictícia nem receita preservada como resultado comprovado.

## 16. Especificação de evolução P1

### 16.1 Financeiro e PSP

- Escolher um provedor após validar requisitos e documentação atual; integração via adapter.
- PaymentPlan, Invoice, PaymentTransaction e conciliação por tenant.
- Invoice: draft, open, overdue, paid, void; estorno e pagamento parcial precisam de estados/eventos definidos antes de habilitar.
- Transação financeira com valores precisos, moeda e IDs do provedor.
- Webhooks autenticados e deduplicados por provedor/evento, com tolerância a ordem diferente de entrega.
- Não confiar em retorno do navegador para confirmar pagamento.
- Usar checkout/tokenização do PSP; não armazenar cartão bruto.
- Reconciliar estado consultando provedor quando necessário; falha de comunicação não significa pagamento recusado.
- Taxas, recebimento e papel contratual definidos antes de qualquer fluxo de movimentação real.
- Aceite: webhook duplicado não baixa duas vezes; evento atrasado não regride pagamento confirmado; nenhuma cobrança cruza tenant.

### 16.2 Diário e metas

- Diário privado do aluno adulto, com data, texto e tags opcionais.
- Professores e owner sem leitura por padrão; exportação individual autorizada.
- Meta semanal opcional, ajustável e pausável, sem pressão para treinar lesionado ou compensar descanso.
- Marcos por participações válidas e tempo conhecido; correção de presença recalcula marcos sem apagar evidência de revisão.
- Sem ranking público ou relação automática com graduação.

### 16.3 IA

- Somente após contexto de domínio e dados confiáveis.
- Resumo semanal, resumo administrativo permitido e rascunho de contato.
- Provedor configurado por adapter, orçamento, timeout e controle de dados enviados.
- Resposta deve apontar dados objetivos usados; não inferir saúde, caráter ou mérito técnico.
- Sem consulta SQL arbitrária gerada pelo modelo e executada diretamente.
- Texto de usuário/documento é dado não confiável; nunca altera permissões ou instruções do serviço.
- Mensagem é rascunho revisável; envio exige ação humana.
- Falta de chave ou limite de orçamento desabilita a função com explicação, preservando o fluxo sem IA.

### 16.4 Leads e experimentais

- Funil separado: NEW, SCHEDULED, ATTENDED, NO_SHOW, CONVERTED, CLOSED.
- Coletar contato mínimo, permitir agendamento em sessões habilitadas e registrar follow-up.
- Converter cria aluno/vínculo de modo idempotente; não duplicar pessoa já cadastrada.
- Comunicações promocionais têm preferência própria e encerramento de contato.

## 17. Plano de implementação por entregas verificáveis

| Entrega | Escopo | Evidência de conclusão |
|---|---|---|
| E0 | Inspeção, ADRs, estrutura, contratos iniciais e ambiente | Serviços locais iniciam; versões e comandos documentados |
| E1 | Auth, tenant, equipe, alunos e importação | Duas academias isoladas; importação válida/invalidada testada |
| E2 | Turmas, sessões e chamada no painel Flutter Web | Owner cadastra e conclui chamada real persistida |
| E3 | Retenção, pausas e CRM | Dados sintéticos produzem alertas corretos e acompanhamento completo |
| E4 | Adaptação mobile do Flutter para professor, QR e fila offline | Reinício/reconexão preservam chamada sem duplicação |
| E5 | Graduação, jornada aluno/responsável e avisos | Fluxos por papel completos, notas internas inacessíveis |
| E6 | Relatórios, exportação, operação comercial e robustez | P0 integral validado, restauração e runbooks testados |
| E7 | Piloto com 3–5 academias | Uso real, suporte e primeiras cobranças acompanhados |
| E8 | P1 priorizado pelos resultados | Cada módulo atende seu gate e critérios próprios |

O piloto inicial assistido pode começar depois de E3 com chamada web; isso não significa que todo o P0 esteja concluído. Não construir P1 automaticamente enquanto o P0 ainda tiver falhas essenciais.

## 18. Estratégia de testes

Priorizar invariantes, regras de negócio, autorização e jornadas reais. Não criar testes que apenas reproduzem detalhes internos sem validar comportamento.

### 18.1 Casos críticos obrigatórios

1. Tenant A não lê, altera, exporta ou recebe notificações de B.
2. Student não acessa outro aluno; Guardian só acessa dependentes ativos.
3. Instructor sem capacidade não promove, mesmo chamando API diretamente.
4. Importação confirmada duas vezes mantém uma única execução.
5. Dois irmãos com contato compartilhado não são mesclados.
6. Presença concorrente e reenvio offline resultam em um registro lógico.
7. Correção de presença muda indicadores e mantém auditoria.
8. QR inválido, expirado, de outra unidade ou fora da janela falha.
9. Offline com sessão cancelada ou permissão revogada exige revisão.
10. Retenção com score 39/40/59/60/79/80 respeita fronteiras.
11. Histórico insuficiente, baixa cobertura, pausa e fechamento não geram falso score.
12. Job diário duplicado não gera novo alerta/tarefa.
13. Retorno sem contato não conta como retorno após contato.
14. Cancelamento durante pausa impede reativação automática.
15. Promoções concorrentes geram conflito e não corrompem nível atual.
16. Webhook financeiro repetido e fora de ordem é seguro quando P1 existir.
17. Push indisponível não bloqueia presença.
18. Restauração recupera um conjunto verificável de dados e vínculos.

### 18.2 Camadas

- Unitários para score, elegibilidade, transições e datas.
- Integração com PostgreSQL real em container para constraints, isolamento, importação e outbox.
- Contrato para DTOs e erros públicos.
- E2E no Flutter Web para onboarding → chamada → alerta → contato → retorno, verificando comportamento acessível e resultados persistidos, sem pressupor uma árvore de elementos HTML convencional.
- Testes Flutter de componentes essenciais em layouts compactos e amplos, e integração mobile para persistência/sincronização offline.
- No web, validar recarregamento de rota interna, histórico do navegador, sessão por cookie, expiração, troca de academia, teclado, foco e ausência de overflow em tabelas/formulários.
- Verificação manual documentada de teclado, leitor de tela, câmera e dispositivos reais do piloto.
- Android pode ser compilado em ambiente compatível; build/validação iOS exige ambiente Apple apropriado. Registrar essa limitação quando o desenvolvimento ocorrer no Windows.

## 19. Dados de demonstração

Seed apenas em desenvolvimento/teste, reexecutável e com referência temporal controlável:

- Duas academias isoladas, uma unidade cada.
- Usuários de papéis diferentes por academia e responsável com dois dependentes.
- Cerca de 30 alunos por academia, com nomes e contatos claramente fictícios.
- Oito semanas de sessões/presenças: regular, queda recente, pausa, novo sem presença, cancelado, retorno após contato e dados insuficientes.
- Histórico de faixa inicial e uma promoção corrigida.
- Lote CSV válido, inválido e com duplicatas potenciais.
- Não colocar senhas de produção ou credenciais fixas reutilizáveis em ambiente publicado.

## 20. Definition of Done e entrega final

Uma funcionalidade só está concluída quando interface, API, persistência, permissões, estados de erro e critérios de aceite correspondentes estiverem implementados e verificados.

P0 concluído exige:

- Fluxo principal integral conectado a backend e banco; nenhum mock oculto em produção.
- Migrações reproduzíveis, seed de demonstração e contratos atualizados.
- Testes críticos aprovados ou bloqueios reais explicitamente documentados.
- README com instalação, configuração, execução, testes e solução dos erros comuns.
- `.env.example` sem segredos, lista de integrações opcionais e comportamento sem credenciais.
- Runbooks para backup/restauração, fila offline, job de retenção, indisponibilidade de push e incidente de acesso.
- Registro de implementado, pendente e limitações em `docs/implementation-status.md`.
- Nenhuma promessa de compatibilidade, entrega de notificação, efeito sobre evasão ou resultado financeiro sem evidência.
- Revisão do piloto demonstra que uma academia consegue executar a rotina sem intervenção diária do desenvolvedor.

## 21. Decisões a validar sem bloquear o início local

Registre as seguintes escolhas como hipóteses e use os padrões deste PRD até evidência contrária:

- Nome e identidade visual definitivos.
- Versões compatíveis de bibliotecas e requisitos mínimos dos aparelhos.
- Preço e política comercial final.
- Parâmetros de retenção e intervalos do piloto.
- Provedor de hospedagem, e-mail, push e pagamentos.
- Políticas contratuais, tratamento de menores e prazos definitivos de retenção.

Credenciais, publicação e movimentação financeira só são necessárias na etapa correspondente. Sua ausência não impede desenvolver localmente os fluxos independentes, mas deve ser registrada sem fingir integração real.
