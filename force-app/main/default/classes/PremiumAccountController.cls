public with sharing class PremiumAccountController {
    
    public static List<Account> PremiumAccountController(String term) {
        return getPremiumAccounts(term);
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getPremiumAccounts(String term) {
        if (String.isBlank(term)) {
            return null;
        }
        String searchTerm = '%' + term + '%';
        List<Account> premiumAccounts = [SELECT Id, Name, RecordTypeId, RecordType.Name FROM Account WHERE Name like :searchTerm];
        return premiumAccounts;
    }
}