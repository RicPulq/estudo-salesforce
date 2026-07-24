@IsTest
private class AsyncProcessingErrorLoggerTest {
    @IsTest
    static void logMethodsCaptureDmlAndUnhandledErrorsDuringTests() {
        AsyncProcessingErrorLogger.capturedErrors.clear();
        List<Account> invalidAccounts = new List<Account>{ new Account(Name = 'No Id') };
        Database.SaveResult[] saveResults = Database.update(invalidAccounts, false);

        Test.startTest();
        AsyncProcessingErrorLogger.LoggingContext context =
            new AsyncProcessingErrorLogger.LoggingContext(
                'TestProcessor',
                UserInfo.getUserId(),
                new List<Id>{ UserInfo.getUserId() }
            );
        AsyncProcessingErrorLogger.logSaveResults(context, saveResults);
        try {
            String nullValue;
            nullValue.length();
        } catch (Exception errorException) {
            AsyncProcessingErrorLogger.logException(context, errorException);
        }
        Test.stopTest();

        System.assertEquals('TestProcessor', context.processorName);
        System.assertEquals(UserInfo.getUserId(), context.jobId);
        System.assertEquals(1, context.recordIds.size());
        System.assertEquals(2, AsyncProcessingErrorLogger.capturedErrors.size());
        System.assertEquals(
            'TestProcessor',
            AsyncProcessingErrorLogger.capturedErrors[0].Processor__c
        );
        System.assertNotEquals(
            null,
            AsyncProcessingErrorLogger.capturedErrors[0].Error_Message__c
        );
    }

    @IsTest
    static void logMethodsIgnoreInvalidContextsAndLogEmptyRecordIds() {
        AsyncProcessingErrorLogger.capturedErrors.clear();
        Database.SaveResult[] saveResults = Database.update(
            new List<Account>{ new Account(Name = 'No Id') },
            false
        );
        AsyncProcessingErrorLogger.logSaveResults(null, saveResults);
        AsyncProcessingErrorLogger.logSaveResults(
            new AsyncProcessingErrorLogger.LoggingContext(
                'TestProcessor',
                UserInfo.getUserId(),
                new List<Id>()
            ),
            saveResults
        );

        Exception capturedException;
        try {
            String nullValue;
            nullValue.length();
        } catch (Exception errorException) {
            capturedException = errorException;
        }
        AsyncProcessingErrorLogger.logException(null, capturedException);
        AsyncProcessingErrorLogger.logException(
            new AsyncProcessingErrorLogger.LoggingContext(
                'TestProcessor',
                UserInfo.getUserId(),
                new List<Id>()
            ),
            capturedException
        );

        System.assertEquals(1, AsyncProcessingErrorLogger.capturedErrors.size());
        System.assertEquals(
            null,
            AsyncProcessingErrorLogger.capturedErrors[0].Record_Id__c
        );
    }
}
