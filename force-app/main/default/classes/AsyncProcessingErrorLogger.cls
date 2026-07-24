/**
 * Persiste falhas de DML de jobs assíncronos para auditoria administrativa.
 */
public with sharing class AsyncProcessingErrorLogger {
    @TestVisible
    private static List<Async_Processing_Error__c> capturedErrors =
        new List<Async_Processing_Error__c>();

    /**
     * Agrupa o contexto de uma operação assíncrona que pode gerar erros de DML.
     */
    public class LoggingContext {
        public final String processorName;
        public final Id jobId;
        public final List<Id> recordIds;

        /**
         * Cria o contexto imutável de uma operação assíncrona.
         *
         * @param processorName Nome do processador que executou a operação.
         * @param jobId Identificador do job assíncrono.
         * @param recordIds Identificadores relacionados à operação DML.
         */
        public LoggingContext(String processorName, Id jobId, List<Id> recordIds) {
            this.processorName = processorName;
            this.jobId = jobId;
            this.recordIds = recordIds == null ? new List<Id>() : new List<Id>(recordIds);
        }
    }

    /**
     * Registra os resultados malsucedidos de uma operação DML parcial.
     *
     * @param context Contexto da operação DML.
     * @param saveResults Resultados retornados pela operação DML.
     */
    public static void logSaveResults(
        LoggingContext context,
        Database.SaveResult[] saveResults
    ) {
        if (context == null || saveResults == null || context.recordIds.size() != saveResults.size()) {
            return;
        }

        List<Async_Processing_Error__c> errorsToInsert = new List<Async_Processing_Error__c>();
        for (Integer indexNumber = 0; indexNumber < saveResults.size(); indexNumber++) {
            if (!saveResults[indexNumber].isSuccess()) {
                errorsToInsert.add(new Async_Processing_Error__c(
                    Processor__c = context.processorName,
                    Job_Id__c = String.valueOf(context.jobId),
                    Record_Id__c = String.valueOf(context.recordIds[indexNumber]),
                    Error_Message__c = formatErrors(saveResults[indexNumber].getErrors())
                ));
            }
        }
        insertErrors(errorsToInsert);
    }

    /**
     * Registra uma exceção não tratada por um job assíncrono.
     *
     * @param context Contexto do job que falhou.
     * @param errorException Exceção retornada pelo job.
     */
    public static void logException(
        LoggingContext context,
        Exception errorException
    ) {
        if (context == null || errorException == null) {
            return;
        }

        insertErrors(new List<Async_Processing_Error__c>{
            new Async_Processing_Error__c(
                Processor__c = context.processorName,
                Job_Id__c = String.valueOf(context.jobId),
                Record_Id__c = context.recordIds.isEmpty()
                    ? null
                    : String.valueOf(context.recordIds[0]),
                Error_Message__c = errorException.getTypeName() + ': ' + errorException.getMessage()
            )
        });
    }

    private static void insertErrors(List<Async_Processing_Error__c> errorsToInsert) {
        if (errorsToInsert.isEmpty()) {
            return;
        }
        if (Test.isRunningTest()) {
            capturedErrors.addAll(errorsToInsert);
            return;
        }
        Database.insert(errorsToInsert, false, AccessLevel.SYSTEM_MODE);
    }

    private static String formatErrors(Database.Error[] errors) {
        List<String> messages = new List<String>();
        for (Database.Error errorRecord : errors) {
            messages.add(errorRecord.getStatusCode() + ': ' + errorRecord.getMessage());
        }
        return String.join(messages, ' | ');
    }
}
