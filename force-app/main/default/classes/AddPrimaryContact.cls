/**
 * Inicia a criação assíncrona de contatos primários para contas de um estado.
 */
public with sharing class AddPrimaryContact {
    /**
     * Inicia um Batch Apex para criar contatos que ainda não existem.
     *
     * @param contactTemplate Modelo que fornece FirstName, LastName e Email.
     * @param stateAbbreviation Estado das contas a processar.
     * @return Identificador do job Batch Apex criado.
     * @throws IllegalArgumentException Quando o modelo ou o estado é inválido.
     */
    public static Id start(Contact contactTemplate, String stateAbbreviation) {
        if (contactTemplate == null || String.isBlank(contactTemplate.LastName)) {
            throw new IllegalArgumentException('A contact template with LastName is required.');
        }
        if (String.isBlank(stateAbbreviation)) {
            throw new IllegalArgumentException('A state abbreviation is required.');
        }

        return Database.executeBatch(
            new AddPrimaryContactBatch(
                new AddPrimaryContactBatch.ContactTemplate(
                    contactTemplate.FirstName,
                    contactTemplate.LastName,
                    contactTemplate.Email
                ),
                stateAbbreviation.trim()
            ),
            200
        );
    }
}
