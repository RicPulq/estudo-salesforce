/**
 * Recalcula o total de contatos das contas recebidas em uma transação assíncrona.
 */
public with sharing class AccountContactCountQueueable implements Queueable, Finalizer {
    private final Set<Id> accountIds;

    /**
     * Cria um job para recalcular os totais das contas recebidas.
     *
     * @param accountIds Identificadores das contas a processar.
     */
    public AccountContactCountQueueable(Set<Id> accountIds) {
        this.accountIds = accountIds == null ? new Set<Id>() : new Set<Id>(accountIds);
    }

    /**
     * Recalcula os totais e persiste somente valores alterados.
     *
     * @param context Contexto do job Queueable.
     */
    public void execute(QueueableContext context) {
        System.attachFinalizer(this);
        if (accountIds.isEmpty()) {
            return;
        }

        Map<Id, Integer> contactCountsByAccount = new Map<Id, Integer>();
        List<SObject> groupedContactResults = Database.queryWithBinds(
            'SELECT AccountId accountId, COUNT(Id) contactCount ' +
                'FROM Contact WHERE AccountId IN :accountIds GROUP BY AccountId',
            new Map<String, Object>{ 'accountIds' => accountIds },
            AccessLevel.USER_MODE
        );
        for (SObject groupedContactResult : groupedContactResults) {
            AggregateResult groupedContacts = (AggregateResult) groupedContactResult;
            contactCountsByAccount.put(
                (Id) groupedContacts.get('accountId'),
                (Integer) groupedContacts.get('contactCount')
            );
        }

        List<Account> accountsToUpdate = new List<Account>();
        for (Account accountRecord : [
            SELECT Id, Number_Of_Contacts__c
            FROM Account
            WHERE Id IN :accountIds
            WITH USER_MODE
        ]) {
            Integer contactCount = contactCountsByAccount.containsKey(accountRecord.Id)
                ? contactCountsByAccount.get(accountRecord.Id)
                : 0;
            if (accountRecord.Number_Of_Contacts__c != contactCount) {
                accountsToUpdate.add(new Account(
                    Id = accountRecord.Id,
                    Number_Of_Contacts__c = contactCount
                ));
            }
        }

        if (accountsToUpdate.isEmpty()) {
            return;
        }

        Database.SaveResult[] saveResults = Database.update(
            accountsToUpdate,
            false,
            AccessLevel.USER_MODE
        );
        List<Id> updatedAccountIds = new List<Id>();
        for (Account accountRecord : accountsToUpdate) {
            updatedAccountIds.add(accountRecord.Id);
        }
        AsyncProcessingErrorLogger.logSaveResults(
            new AsyncProcessingErrorLogger.LoggingContext(
                'AccountContactCountQueueable',
                context.getJobId(),
                updatedAccountIds
            ),
            saveResults
        );
    }

    /**
     * Registra falhas não tratadas pelo job Queueable.
     *
     * @param context Contexto de finalização do job.
     */
    public void execute(FinalizerContext context) {
        logUnhandledException(
            context.getResult(),
            context.getAsyncApexJobId(),
            context.getException()
        );
    }

    /**
     * Registra o erro retornado pelo Finalizer quando o job termina com exceção.
     *
     * @param result Resultado final do job pai.
     * @param jobId Identificador do job pai.
     * @param errorException Exceção não tratada pelo job pai.
     */
    @TestVisible
    private static void logUnhandledException(
        ParentJobResult result,
        Id jobId,
        Exception errorException
    ) {
        if (result == ParentJobResult.UNHANDLED_EXCEPTION) {
            AsyncProcessingErrorLogger.logException(
                new AsyncProcessingErrorLogger.LoggingContext(
                    'AccountContactCountQueueable',
                    jobId,
                    new List<Id>{ null }
                ),
                errorException
            );
        }
    }
}
