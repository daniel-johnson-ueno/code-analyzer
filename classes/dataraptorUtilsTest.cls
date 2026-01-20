@IsTest
public class dataraptorUtilsTest {
    
    @IsTest
    static void testCallWithCapitalize() {
        dataraptorUtils utils = new dataraptorUtils();
        Map<String, Object> input = new Map<String, Object>();
        List<Object> arguments = new List<Object>{ 'hello world' };
        input.put('arguments', arguments);
        Map<String, Object> args = new Map<String, Object>();
        args.put('input', input);
        args.put('output', new Map<String, Object>());
        args.put('options', new Map<String, Object>());
        utils.call('capitalize', args);
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        String result = (String)output.get('result');

    }
    
    @IsTest
    static void testCallWithGetPicklistLabel() {
        dataraptorUtils utils = new dataraptorUtils();
        Map<String, Object> input = new Map<String, Object>();
        List<Object> arguments = new List<Object>{ 'Account', 'Industry', 'Technology' };
        input.put('arguments', arguments);
        Map<String, Object> args = new Map<String, Object>();
        args.put('input', input);
        args.put('output', new Map<String, Object>());
        args.put('options', new Map<String, Object>());    
        utils.call('getPicklistLabel', args);
        Map<String, Object> output = (Map<String, Object>)args.get('output');
        String result = (String)output.get('result');
        

    }
    
    @IsTest
    static void testCapitalizeText() {

        String result = dataraptorUtils.capitalizeText('hello world');
    }
    
    @IsTest
    static void testGetPicklistLabel() {
        String label = dataraptorUtils.getPicklistLabel('Account', 'Industry', 'Technology');
    }
    
    @IsTest
    static void testInvokeMethodWithInvalidAction() {
        dataraptorUtils utils = new dataraptorUtils();
        Map<String, Object> input = new Map<String, Object>();
        Map<String, Object> args = new Map<String, Object>();
        args.put('input', input);
        args.put('output', new Map<String, Object>());
        args.put('options', new Map<String, Object>());
        Boolean result = utils.invokeMethod('invalidAction', input, (Map<String, Object>)args.get('output'), (Map<String, Object>)args.get('options'));
    }
}