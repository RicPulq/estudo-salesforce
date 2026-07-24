@IsTest
private class DailyLeadProcessorTest {
    @IsTest
    static void scheduledJobStartsBatchProcessing() {
        Lead leadWithoutSource = new Lead(LastName = 'Scheduled Lead', Company = 'Test Company');
        Lead leadWithSource = new Lead(
            LastName = 'Scheduled Web Lead',
            Company = 'Test Company',
            LeadSource = 'Web'
        );
        insert new List<Lead>{ leadWithoutSource, leadWithSource };

        Test.startTest();
        Id jobId = System.schedule(
            'Daily Lead Processor Test ' + String.valueOf(DateTime.now().getTime()),
            '0 0 0 15 3 ? 2042',
            new DailyLeadProcessor()
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId);
        System.assertEquals(1, [SELECT COUNT() FROM CronTrigger WHERE Id = :jobId]);
    }
}
