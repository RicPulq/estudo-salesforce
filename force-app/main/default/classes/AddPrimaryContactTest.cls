@IsTest
private class AddPrimaryContactTest {
    @TestSetup
    static void createData() {
        List<Account> accounts = new List<Account>();
        for (Integer indexNumber = 0; indexNumber < 200; indexNumber++) {
            accounts.add(new Account(Name = 'California Account ' + indexNumber, BillingState = 'CA'));
        }
        accounts.add(new Account(Name = 'New York Account', BillingState = 'NY'));
        insert accounts;

        insert new Contact(
            AccountId = accounts[0].Id,
            FirstName = 'Primary',
            LastName = 'Contact',
            Email = 'primary@example.com'
        );
    }

    @IsTest
    static void startProcessesAllAccountsAndSkipsExistingContacts() {
        Set<Id> californiaAccountIds = new Map<Id, Account>([
            SELECT Id
            FROM Account
            WHERE BillingState = 'CA'
        ]).keySet();

        Test.startTest();
        Id jobId = AddPrimaryContact.start(
            new Contact(
                FirstName = 'Primary',
                LastName = 'Contact',
                Email = 'primary@example.com'
            ),
            'CA'
        );
        Test.stopTest();

        List<Contact> contacts = [
            SELECT AccountId, FirstName, LastName, Email
            FROM Contact
            WHERE AccountId IN :californiaAccountIds
                AND LastName = 'Contact'
                AND Email = 'primary@example.com'
        ];
        System.assertNotEquals(null, jobId);
        System.assertEquals(200, contacts.size());
        for (Contact contactRecord : contacts) {
            System.assertEquals('Primary', contactRecord.FirstName);
            System.assert(californiaAccountIds.contains(contactRecord.AccountId));
        }
        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM Contact
                WHERE Account.BillingState = 'NY'
                    AND LastName = 'Contact'
                    AND Email = 'primary@example.com'
            ]
        );
    }

    @IsTest
    static void startValidatesTemplateAndState() {
        try {
            AddPrimaryContact.start(null, 'CA');
            System.assert(false, 'An invalid template must fail.');
        } catch (IllegalArgumentException exceptionRecord) {
            System.assert(exceptionRecord.getMessage().contains('LastName'));
        }

        try {
            AddPrimaryContact.start(new Contact(LastName = 'Contact'), ' ');
            System.assert(false, 'An invalid state must fail.');
        } catch (IllegalArgumentException exceptionRecord) {
            System.assert(exceptionRecord.getMessage().contains('state'));
        }
    }

    @IsTest
    static void batchValidatesInputsAndSkipsEmptyOrDuplicateScopes() {
        try {
            new AddPrimaryContactBatch(null, 'CA');
            System.assert(false, 'A null template must fail.');
        } catch (IllegalArgumentException exceptionRecord) {
            System.assert(exceptionRecord.getMessage().contains('LastName'));
        }

        AddPrimaryContactBatch.ContactTemplate template =
            new AddPrimaryContactBatch.ContactTemplate('Primary', 'Contact', 'primary@example.com');
        try {
            new AddPrimaryContactBatch(template, ' ');
            System.assert(false, 'A blank state must fail.');
        } catch (IllegalArgumentException exceptionRecord) {
            System.assert(exceptionRecord.getMessage().contains('state'));
        }

        AddPrimaryContactBatch batch = new AddPrimaryContactBatch(template, 'CA');
        batch.execute(null, new List<SObject>());
        Account accountWithDuplicate = [
            SELECT Id
            FROM Account
            WHERE Name = 'California Account 0'
            LIMIT 1
        ];
        batch.execute(null, new List<SObject>{ accountWithDuplicate });
        batch.finish(null);

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM Contact
                WHERE AccountId = :accountWithDuplicate.Id
                    AND LastName = 'Contact'
                    AND Email = 'primary@example.com'
            ]
        );
    }
}
