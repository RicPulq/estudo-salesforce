/**
 * Enfileira o recálculo assíncrono de contatos para contas informadas.
 */
public with sharing class AccountProcessor {
    /**
     * Enfileira o recálculo do campo Number_Of_Contacts__c.
     *
     * @param accountIds Identificadores das contas a processar.
     */
    public static void countContacts(List<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }

        Set<Id> uniqueAccountIds = new Set<Id>(accountIds);
        uniqueAccountIds.remove(null);
        if (uniqueAccountIds.isEmpty()) {
            return;
        }

        System.enqueueJob(new AccountContactCountQueueable(uniqueAccountIds));
    }
}
