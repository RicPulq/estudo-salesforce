---
name: soql-query-builder
description: Crie, explique, formate ou otimize consultas SOQL e SOSL para Apex, LWC e integrações Salesforce. Use quando a tarefa pedir consultas, filtros, relacionamentos entre objetos, busca SOSL ou desempenho de consulta.
---

# Montar consultas SOQL e SOSL

1. Identifique o SObject, os campos necessários, filtros, ordenação e limite de resultados.
2. Use relacionamento child-to-parent com notação de ponto e parent-to-child com subconsulta somente quando necessário.
3. Adicione restrições e filtros de segurança, como a cláusula `WITH SECURITY_ENFORCED` ou `WITH USER_MODE`, caso a consulta vá retornar dados para o frontend (LWC/Aura/Visualforce).
  - Se a consulta alimentar interface de usuário, aplique o modo de segurança adequado, como `WITH USER_MODE`, conforme o contexto do código.
4. Selecione apenas os campos usados e inclua `LIMIT` quando o requisito pedir quantidade fixa ou único registro.
5. Prefira filtros seletivos; sinalize consultas potencialmente custosas em grandes volumes.
6. Retorne a consulta SQL bem formatada (em múltiplas linhas, se for longa) e inclua um exemplo rápido de como executar essa query no Apex (List ou iteração SOQL for loop).

Não suponha nomes de objetos ou campos que não existam no repositório ou que não tenham sido informados.