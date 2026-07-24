# Processamento assíncrono

## Recalcular contatos de contas

Use `AccountProcessor.countContacts(accountIds)` para enfileirar o recálculo de `Number_Of_Contacts__c`. A chamada não é síncrona; consulte o job assíncrono e os registros de erro para acompanhar o resultado.

## Criar contatos primários

Use `AddPrimaryContact.start(contactTemplate, stateAbbreviation)` para iniciar o Batch Apex. O template utiliza somente `FirstName`, `LastName` e `Email`; `LastName` e o estado são obrigatórios. Uma conta é ignorada se já possuir um contato com o mesmo `LastName` e `Email`.

## Origem dos leads

`LeadProcessor` e `DailyLeadProcessor` processam somente leads sem `LeadSource`. A origem aplicada vem do registro `Default` de `Lead_Processing_Config__mdt`.

## Auditoria de falhas

Falhas parciais são registradas em `Async_Processing_Error__c` com o processador, o Job Id, o registro afetado e a mensagem do erro. O objeto é privado e deve ser consultado por administradores autorizados.
