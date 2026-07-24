/**
 * Cria contatos primários para todas as contas de um estado, sem duplicar o template.
 */
public with sharing class AddPrimaryContactBatch implements Database.Batchable<SObject> {
    private final ContactTemplate contactTemplate;
    private final String stateAbbreviation;

    /**
     * Representa os campos permitidos do contato que será criado.
     */
    public class ContactTemplate {
        public final String firstName;
        public final String lastName;
        public final String email;

        /**
         * Cria um template imutável de contato.
         *
         * @param firstName Primeiro nome do contato.
         * @param lastName Sobrenome do contato.
         * @param email E-mail do contato.
         */
        public ContactTemplate(String firstName, String lastName, String email) {
            this.firstName = firstName;
            this.lastName = lastName;
            this.email = email;
        }
    }

    /**
     * Cria um Batch Apex para o template e estado informados.
     *
     * @param contactTemplate Campos permitidos do contato a criar.
     * @param stateAbbreviation Estado das contas a processar.
     */
    public AddPrimaryContactBatch(ContactTemplate contactTemplate, String stateAbbreviation) {
        if (contactTemplate == null || String.isBlank(contactTemplate.lastName)) {
            throw new IllegalArgumentException('A contact template with LastName is required.');
        }
        if (String.isBlank(stateAbbreviation)) {
            throw new IllegalArgumentException('A state abbreviation is required.');
        }
        this.contactTemplate = contactTemplate;
        this.stateAbbreviation = stateAbbreviation.trim();
    }

    /**
     * Localiza as contas elegíveis para receber o contato primário.
     *
     * @param context Contexto do Batch Apex.
     * @return QueryLocator para as contas elegíveis.
     */
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Account
            WHERE BillingState = :stateAbbreviation
            WITH USER_MODE
        ]);
    }

    /**
     * Cria contatos apenas para contas sem um contato de mesmo sobrenome e e-mail.
     *
     * @param context Contexto do Batch Apex.
     * @param scope Contas do escopo atual.
     */
    public void execute(Database.BatchableContext context, List<SObject> scope) {
        if (scope.isEmpty()) {
            return;
        }

        List<Account> accounts = new List<Account>();
        Set<Id> accountIds = new Set<Id>();
        for (SObject scopeRecord : scope) {
            Account accountRecord = (Account) scopeRecord;
            accounts.add(accountRecord);
            accountIds.add(accountRecord.Id);
        }
        Set<Id> accountIdsWithDuplicate = new Set<Id>();
        String templateLastName = contactTemplate.lastName;
        String templateEmail = contactTemplate.email;
        for (Contact existingContact : [
            SELECT AccountId
            FROM Contact
            WHERE AccountId IN :accountIds
                AND LastName = :templateLastName
                AND Email = :templateEmail
            WITH USER_MODE
        ]) {
            accountIdsWithDuplicate.add(existingContact.AccountId);
        }

        List<Contact> contactsToInsert = new List<Contact>();
        List<Id> accountIdsForContacts = new List<Id>();
        for (Account accountRecord : accounts) {
            if (!accountIdsWithDuplicate.contains(accountRecord.Id)) {
                contactsToInsert.add(new Contact(
                    AccountId = accountRecord.Id,
                    FirstName = contactTemplate.firstName,
                    LastName = contactTemplate.lastName,
                    Email = contactTemplate.email
                ));
                accountIdsForContacts.add(accountRecord.Id);
            }
        }

        if (contactsToInsert.isEmpty()) {
            return;
        }

        Database.SaveResult[] saveResults = Database.insert(
            contactsToInsert,
            false,
            AccessLevel.USER_MODE
        );
        AsyncProcessingErrorLogger.logSaveResults(
            new AsyncProcessingErrorLogger.LoggingContext(
                'AddPrimaryContactBatch',
                context.getJobId(),
                accountIdsForContacts
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
