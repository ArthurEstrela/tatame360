# ADR 001 — Base de implementação

Decisão: um projeto Flutter para web, Android e iOS; API Java 21/Spring Boot 3.5.16 e PostgreSQL 17.6. A versão Spring foi verificada na documentação oficial e está disponível no cache local. Não introduzir Next.js.

Primeira entrega vertical: login com tokens opacos revogáveis, cadastro, turma, sessão e chamada persistida. JDBC mantém o escopo do tenant explícito em cada consulta; constraints compostas impedem referências entre academias. OpenAPI acompanha o que está implementado.

O Java 21 disponível está no runtime do Android Studio. O SDK Flutter 3.47.1 tem um inicializador batch que trava neste ambiente; executar seu snapshot com o Dart instalado contorna o problema sem alterar o SDK do usuário.

Outbox registra eventos transacionalmente. Não afirmar entrega de push nem efeitos externos antes de implementar consumidores e configurar provedores.
