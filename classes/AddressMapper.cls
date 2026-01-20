public class AddressMapper {
    public static Account mapAddressFields(String campo, List<Object> addresses, Account account) {
        if (addresses != null && !addresses.isEmpty()) {
            Map<String, Object> parsedAddress = (Map<String, Object>) addresses.get(0);
            String addressType = (String) parsedAddress.get('type');
            if (addressType == 'P') {
               account= mapShippingAddress(campo, parsedAddress, account);
            } else if (addressType == 'L') {
               account= mapBillingAddress(campo, parsedAddress, account);
            }
            if(addresses.size()>1){
                Map<String, Object> secondAddress = (Map<String, Object>) addresses.get(1);
                String secondAddressType = (String) secondAddress.get('type');
                if (secondAddressType == 'P') {
                    account= mapShippingAddress(campo, secondAddress, account);
                } else if (secondAddressType == 'L') {
                    account= mapBillingAddress(campo, secondAddress, account);
                }
            }
        }
        return account;
    }

    private static account mapShippingAddress(String campo, Map<String, Object> addressMap, Account account) {
        
        if (campo == 'ShippingLatitude' && addressMap.get('latitude') != null) {
            account.put('ShippingLatitude', getDecimalValue(addressMap, 'latitude'));
        } else if (campo == 'ShippingPostalCode') {
            account.put('ShippingPostalCode', (String) addressMap.get('postalCode'));
        } else if (campo == 'ShippingCity') {
            account.put('ShippingCity', (String) addressMap.get('city'));
        } else if (campo == 'ShippingLongitude' && addressMap.get('longitude') != null) {
            account.put('ShippingLongitude', getDecimalValue(addressMap, 'longitude'));
        } else if (campo == 'ShippingState') {
            account.put('ShippingState', (String) addressMap.get('state'));
        } else if (campo == 'ShippingStreet') {
            account.put('ShippingStreet', (String) addressMap.get('street'));
        } else if (campo == 'ShippingCountry') {
            account.put('ShippingCountry', (String) addressMap.get('country'));
        }
        return account;
    }

    private static account mapBillingAddress(String campo, Map<String, Object> addressMap, Account account) {
        if (campo == 'BillingPostalCode') {
            account.put('BillingPostalCode',(String) addressMap.get('postalCode'));
        } else if (campo == 'BillingState') {
            account.put('BillingState',(String) addressMap.get('state'));
        } else if (campo == 'BillingStreet') {
            account.put('BillingStreet',(String) addressMap.get('street'));
        } else if (campo == 'BillingCity') {
            account.put('BillingCity',(String) addressMap.get('city'));
        } else if (campo == 'BillingLatitude' && addressMap.get('latitude') != null) {
            account.put('BillingLatitude',getDecimalValue(addressMap, 'latitude'));
        } else if (campo == 'BillingLongitude' && addressMap.get('longitude') != null) {
            account.put('BillingLongitude',getDecimalValue(addressMap, 'longitude'));
        } else if (campo == 'BillingCountry') {
            account.put('BillingCountry',(String) addressMap.get('country'));
        }
        return account;
    }

    private static Decimal getDecimalValue(Map<String, Object> addressMap, String field) {
        String value = (String) addressMap.get(field);
        return value != null && value != '' ? Decimal.valueOf(value) : null;
    }
}