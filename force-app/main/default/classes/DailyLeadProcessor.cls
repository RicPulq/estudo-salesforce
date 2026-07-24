/**
 * Agenda o processamento em lote dos leads que ainda não possuem origem.
 */
public with sharing class DailyLeadProcessor implements Schedulable {
    private static final Integer BATCH_SIZE = 200;

    /**
     * Inicia o Batch Apex de leads.
     *
     * @param context Contexto do agendamento.
     */
    public void execute(SchedulableContext context) {
        Database.executeBatch(new LeadProcessor(), BATCH_SIZE);
    }
}
