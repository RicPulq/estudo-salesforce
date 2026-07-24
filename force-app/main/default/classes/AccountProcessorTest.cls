@IsTest
private class AccountProcessorTest {
    @TestSetup
    static void createData() {
        Account accountWithContacts = new Account(
            Name = 'Account with contacts',
            Number_Of_Contacts__c = 0
        );
        Account accountWithoutContacts = new Account(
            Name = 'Account without contacts',
            Number_Of_Contacts__c = 4
        );
        insert new List<Account>{ accountWithContacts, accountWithoutContacts };

        insert new List<Contact>{
            new Contact(LastName = 'First contact', AccountId = accountWithContacts.Id),
            new Contact(LastName = 'Second contact', AccountId = accountWithContacts.Id)
        };
    }

    @IsTest
    static void countContactsUpdatesOnlyRequestedAccounts() {
        Map<String, Account> accountsByName = new Map<String, Account>();
        for (Account accountRecord : [
            SELECT Id, Name
            FROM Account
            WHERE Name IN ('Account with contacts', 'Account without contacts')
        ]) {
            accountsByName.put(accountRecord.Name, accountRecord);
        }

        Test.startTest();
        AccountProcessor.countContacts(new List<Id>{
            accountsByName.get('Account with contacts').Id,
            accountsByName.get('Account with contacts').Id,
            accountsByName.get('Account without contacts').Id
        });
        Test.stopTest();

        Map<String, Account> updatedAccountsByName = new Map<String, Account>();
        for (Account accountRecord : [
            SELECT Name, Number_Of_Contacts__c
            FROM Account
            WHERE Name IN ('Account with contacts', 'Account without contacts')
        ]) {
            updatedAccountsByName.put(accountRecord.Name, accountRecord);
        }
        System.assertEquals(
            2,
            updatedAccountsByName.get('Account with contacts').Number_Of_Contacts__c
        );
        System.assertEquals(
            0,
            updatedAccountsByName.get('Account without contacts').Number_Of_Contacts__c
        );
    }

    @IsTest
    static void countContactsAcceptsNullAndEmptyInputs() {
        Test.startTest();
        AccountProcessor.countContacts(null);
        AccountProcessor.countContacts(new List<Id>());
        AccountProcessor.countContacts(new List<Id>{ null });
        Test.stopTest();

        System.assertEquals(2, [SELECT COUNT() FROM Account]);
    }

    @IsTest
    static void queueableHandlesEmptyAndUnchangedAccountSets() {
        Account accountWithContacts = [
            SELECT Id, Number_Of_Contacts__c
            FROM Account
            WHERE Name = 'Account with contacts'
            LIMIT 1
        ];
        accountWithContacts.Number_Of_Contacts__c = 2;
        update accountWithContacts;

        Test.startTest();
        System.enqueueJob(new AccountContactCountQueueable(new Set<Id>()));
        AccountProcessor.countContacts(new List<Id>{ accountWithContacts.Id });
        Test.stopTest();

        System.assertEquals(
            2,
            [
                SELECT Number_Of_Contacts__c
                FROM Account
                WHERE Id = :accountWithContacts.Id
            ].Number_Of_Contacts__c
        );
    }

    @IsTest
    static void queueableLogsUnhandledFinalizerExceptions() {
        AsyncProcessingErrorLogger.capturedErrors.clear();
        Exception capturedException;
        try {
            String nullValue;
            nullValue.length();
        } catch (Exception errorException) {
            capturedException = errorException;
        }

        AccountContactCountQueueable.logUnhandledException(
            ParentJobResult.UNHANDLED_EXCEPTION,
            UserInfo.getUserId(),
            capturedException
        );

        System.assertEquals(1, AsyncProcessingErrorLogger.capturedErrors.size());
        System.assertEquals(
            'AccountContactCountQueueable',
            AsyncProcessingErrorLogger.capturedErrors[0].Processor__c
        );
    }
}
