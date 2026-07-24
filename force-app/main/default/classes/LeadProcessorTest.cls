@IsTest
private class LeadProcessorTest {
    @TestSetup
    static void createData() {
        List<Lead> leads = new List<Lead>();
        for (Integer indexNumber = 0; indexNumber < 200; indexNumber++) {
            leads.add(new Lead(
                LastName = 'Lead without source ' + indexNumber,
                Company = 'Test Company'
            ));
        }
        leads.add(new Lead(
            LastName = 'Lead with source',
            Company = 'Test Company',
            LeadSource = 'Web'
        ));
        insert leads;
    }

    @IsTest
    static void batchUpdatesOnlyLeadsWithoutSource() {
        Test.startTest();
        Database.executeBatch(new LeadProcessor(), 200);
        Test.stopTest();

        System.assertEquals(200, [SELECT COUNT() FROM Lead WHERE LeadSource = 'Dreamforce']);
        System.assertEquals(1, [SELECT COUNT() FROM Lead WHERE LeadSource = 'Web']);
    }

    @IsTest
    static void processorValidatesConfigurationAndEmptyScopes() {
        try {
            LeadProcessor.resolveTargetLeadSource(null);
            System.assert(false, 'A missing configuration must fail.');
        } catch (IllegalArgumentException exceptionRecord) {
            System.assert(exceptionRecord.getMessage().contains('configuration'));
        }

        new LeadProcessor().execute(null, new List<SObject>());
        System.assertEquals(201, [SELECT COUNT() FROM Lead]);
    }
}
