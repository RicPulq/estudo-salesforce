/**
 * Define a origem configurada para leads que ainda não possuem LeadSource.
 */
public with sharing class LeadProcessor implements Database.Batchable<SObject> {
    private static final String CONFIG_DEVELOPER_NAME = 'Default';
    private final String targetLeadSource;

    /**
     * Cria o processador usando a configuração padrão de Custom Metadata.
     *
     * @throws IllegalArgumentException Quando a configuração não está disponível.
     */
    public LeadProcessor() {
        Lead_Processing_Config__mdt configuration =
            Lead_Processing_Config__mdt.getInstance(CONFIG_DEVELOPER_NAME);
        targetLeadSource = resolveTargetLeadSource(configuration);
    }

    /**
     * Valida e retorna a origem padrão obtida da configuração de Custom Metadata.
     *
     * @param configuration Configuração de processamento de leads.
     * @return Origem de lead configurada.
     */
    @TestVisible
    private static String resolveTargetLeadSource(Lead_Processing_Config__mdt configuration) {
        if (configuration == null || String.isBlank(configuration.Default_Lead_Source__c)) {
            throw new IllegalArgumentException('Lead processing configuration is missing.');
        }
        return configuration.Default_Lead_Source__c;
    }

    /**
     * Localiza os leads que ainda não possuem origem.
     *
     * @param context Contexto do Batch Apex.
     * @return QueryLocator para leads que não possuem origem.
     */
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Lead
            WHERE LeadSource = NULL
            WITH USER_MODE
        ]);
    }

    /**
     * Atualiza somente os leads elegíveis no escopo atual.
     *
     * @param context Contexto do Batch Apex.
     * @param scope Leads do escopo atual.
     */
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        if (scope.isEmpty()) {
            return;
        }

        List<Lead> leadsToUpdate = new List<Lead>();
        List<Id> leadIds = new List<Id>();
        for (SObject scopeRecord : scope) {
            Lead leadRecord = (Lead) scopeRecord;
            leadsToUpdate.add(new Lead(
                Id = leadRecord.Id,
                LeadSource = targetLeadSource
            ));
            leadIds.add(leadRecord.Id);
        }

        Database.SaveResult[] saveResults = Database.update(
            leadsToUpdate,
            false,
            AccessLevel.USER_MODE
        );
        AsyncProcessingErrorLogger.logSaveResults(
            new AsyncProcessingErrorLogger.LoggingContext(
                'LeadProcessor',
                context.getJobId(),
                leadIds
            ),
            saveResults
        );
    }

    /**
     * Finaliza o Batch sem pós-processamento adicional.
     *
     * @param context Contexto de finalização do Batch Apex.
     */
    public void finish(Database.BatchableContext context) {
        return;
    }
}
