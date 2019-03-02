/**
 * Data Factory to create SObject with all fields populated in order to make unit test more efficient.
 *
 * Andrew Wisniowski
 * Andrew@Wizno.net
 * http://Wizno.com
 */
public with sharing class TestDataFactory {

	/* Company Domain Name */
	private static final string DOMAIN_NAME = 'wizno.com';

	private static final User user = [SELECT Id FROM User WHERE IsActive = TRUE AND Profile.Name = 'System Administrator' LIMIT 1];
	private static final Profile profile = [SELECT Id FROM Profile LIMIT 1];

	/**
	 * Don't want to run into any SFDC Limits for describes while creating massive amounts of data
	 */
	private static final Map<String, Schema.SObjectType> globalDescribeMap = Schema.getGlobalDescribe();

	private static Map<String, Map<String, Schema.SObjectField>> fieldDescribeMap= new Map<String, Map<String, Schema.SObjectField>>();

	/**
	 * Create a blank SObject
	 * @param  sObjectType API Name for SObject (Account, Contact, Lead, Custom__c, etc)
	 * @return             empty SObject
	 */
	public static SObject createSkeletonObject(String sObjectType){
		if(!globalDescribeMap.containsKey(sObjectType)){
			return null;
		}

		Schema.SObjectType soType = globalDescribeMap.get(sObjectType);
		populateFieldMap(sObjectType);
		sObject sObjectRecord = soType.newSObject();
		return sObjectRecord;
	}

	/**
	 * Create an SObject complete will all data
	 * @param  sObjectType API Name for SObject (Account, Contact, Lead, Custom__c, etc)
	 * @param  fillOnlyRequired Whether all fields, or only required ones should be populated
	 * @return             SObject with all fields populated
	 */
	public static SObject createFullObject(String sObjectType, Boolean fillOnlyRequired, Boolean createReferences){
		sObject sObjectRecord = createSkeletonObject(sObjectType);
		Map<String, String> defaultValues = new Map<String, String>();
		populateFields(sObjectRecord, sObjectType, defaultValues, fillOnlyRequired, createReferences);
		return sObjectRecord;
	}

	/**
	 * Create an SObject complete will all data AND allow for a map of user specified values
	 * @param  sObjectType API Name for SObject (Account, Contact, Lead, Custom__c, etc)
	 * @param fieldDefaultValues		Map containing the API Names and values of the fields prefilled by User
	 * @param  fillOnlyRequired Whether all fields, or only required ones should be populated
	 * @return             SObject with all fields populated
	 */
	public static SObject createFullObject(String sObjectType, Map<String, String> fieldDefaultValues, Boolean fillOnlyRequired, Boolean createReferences){
		sObject sObjectRecord = createSkeletonObject(sObjectType);
		populateFields(sObjectRecord, sObjectType, fieldDefaultValues, fillOnlyRequired, createReferences);
		return sObjectRecord;
	}

	/**
	 * Populate our fieldDescribeMap with the Object Name > Object Field Map
	 * @param sObjectType SObject API Name
	 */
	private static void populateFieldMap(String sObjectType){
		if(!fieldDescribeMap.containsKey(sObjectType)){
			fieldDescribeMap.put(sObjectType, globalDescribeMap.get(sObjectType).getDescribe().fields.getMap());
		}
	}

	/**
	 * Populates the desired fields on the SObject
	 * @param sObjectRecord              The SObject to fill fields on
	 * @param sObjectType      The type of SObject
	 * @param fieldDefaultValues		Map containing the API Names and values of the fields prefilled by User
	 * @param fillOnlyRequired Whether all fields, or only required ones should be populated
	 */
	private static void populateFields(sObject sObjectRecord, String sObjectType, Map<String, String> fieldDefaultValues, Boolean fillOnlyRequired, Boolean createReferences){
		Map<String, Schema.SObjectField> fieldMap = fieldDescribeMap.get(sObjectType);

		Set<String> globalExcludedFields = new Set<String>{'CleanStatus', 'IncludeBosses'};

		for(String fieldName : fieldMap.keySet()){

			Schema.DescribeFieldResult fieldResult = fieldMap.get(fieldName).getDescribe();

			Schema.DisplayType fieldType = fieldResult.getType();

			if( fieldResult.isCreateable() ){
				if( fieldResult.isNillable() && fillOnlyRequired ){
					continue; //Skip non-required/excluded fields
				} else if(globalExcludedFields.contains(fieldName)){
					System.debug('Skipping Field: ' + fieldName);
					continue;
				}

				Object fieldValue;
				//Skip fields defined by user
				if( fieldDefaultValues.keySet().contains(fieldName) ){
					String fieldDefinedValue = fieldDefaultValues.get(fieldName);
					fieldValue = getFieldValue(fieldResult, sObjectType, createReferences, fieldDefinedValue);
				} else {
					fieldValue = getFieldValue(fieldResult, sObjectType, createReferences, null);
				}
				sObjectRecord.put(fieldName, fieldValue);
			}
		}
	}

	private static Object getFieldValue(Schema.DescribeFieldResult fieldResult, String sObjectType, Boolean createReferences, String fieldDefinedValue){
		Schema.DisplayType fieldType = fieldResult.getType();
		Object fieldValue;

		System.debug('Current Field: ' + fieldResult.getName() + ' / Type: ' + fieldType);
		System.debug('User Defined Value for Field: ' + fieldDefinedValue);

		//TODO: Implement methods to set user defined values

		if( fieldType === Schema.DisplayType.Boolean ){
			fieldValue = getRandomInteger(20) < 10 ? true : false;
		} else if( fieldType === Schema.DisplayType.ComboBox ){
			//TODO: create method to generate a value
			fieldValue = 'Yes';
		} else if( fieldType === Schema.DisplayType.Currency ){
			fieldValue = getRandomDouble( getIntegerString( fieldResult.getPrecision() - fieldResult.getScale() ));
		} else if( fieldType === Schema.DisplayType.Date ){
			fieldValue = Date.today();
		} else if( fieldType === Schema.DisplayType.DateTime ){
			fieldValue = DateTime.now();
		} else if( fieldType === Schema.DisplayType.Double ){
			fieldValue = getRandomDouble( getIntegerString( fieldResult.getPrecision() - fieldResult.getScale() ));
		} else if( fieldType === Schema.DisplayType.Email ){
			fieldValue = getEmail();
		} else if( fieldType === Schema.DisplayType.EncryptedString ){
			fieldValue = getRandomString(fieldResult.getLength());
		} else if( fieldType === Schema.DisplayType.Integer ){
			fieldValue = getRandomInteger( getIntegerString( fieldResult.getDigits() ) );
		} else if( fieldType === Schema.DisplayType.MultiPicklist ){
			fieldValue = getRandomPicklistValue(fieldResult);
		} else if( fieldType === Schema.DisplayType.Percent ){
			fieldValue = getRandomDouble(100);
		} else if( fieldType === Schema.DisplayType.Phone ){
			fieldValue = getRandomPhone();
		} else if( fieldType === Schema.DisplayType.Picklist ){
			fieldValue = getRandomPicklistValue(fieldResult);
		} else if( fieldType === Schema.DisplayType.String ){
			fieldValue = getRandomString(fieldResult.getLength());
		} else if( fieldType === Schema.DisplayType.Reference ){
			fieldValue = getReferenceValue(fieldResult, sObjectType, createReferences);
		} else if( fieldType === Schema.DisplayType.TextArea ){
			fieldValue = getRandomString(fieldResult.getLength());
		} else if( fieldType === Schema.DisplayType.Time ){
			fieldValue = Time.newInstance(1, 2, 3, 4);
		} else if( fieldType === Schema.DisplayType.URL ){
			fieldValue = 'http://' + DOMAIN_NAME;
		} else {
			fieldValue = null;
		}

		return fieldValue;
	}

	private static String getEmail(){
		return getRandomString(5) + '@' + DOMAIN_NAME;
	}

	private static List<String> alphaCharacters = new List<String>{'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z'};

	private static String getRandomString(Integer length){
		String alphaString = '';
		for(Integer i = 0; i<length; i++){
			alphaString += alphaCharacters[getRandomInteger(alphaCharacters.size())];
		}
		return alphaString;
	}

	private static String getRandomPhone(){
		return getIntegerString(3) + '-' + getIntegerString(3) + '-' + getIntegerString(4);
	}

	private static Integer getRandomInteger(Integer maxValue){
		if(maxValue==0) maxValue++;
		return Math.mod(Math.round(Math.random() * maxValue), maxValue);
	}

	private static Double getRandomDouble(Integer maxValue){
		if(maxValue==0) maxValue++;
		return Math.mod(Math.round(Math.random() * maxValue), maxValue) + Math.random();
	}

	private static Integer getIntegerString(Integer length){
		String intString = '';
		for(Integer i = 0; i < length; i++){
			intString += String.valueOf(getRandomInteger(9));
		}
		return Integer.valueOf(intString);
	}

	private static String getRandomPicklistValue(Schema.DescribeFieldResult field){
		List<Schema.PicklistEntry> picklistValues = field.getPicklistValues();
		if(picklistValues.isEmpty()){
			return null;
		}
		return picklistValues[getRandomInteger(picklistValues.size())].value;
	}

	private static String getReferenceValue(Schema.DescribeFieldResult field, String sObjectType, Boolean createReferences){
		String refObj = field.getReferenceTo()[0].getDescribe().getName();
		String fieldValue;
		Set<String> excludedReferences = new Set<String>{'User', 'BusinessHours', 'Group', 'Profile'};
		if(refObj == sObjectType || excludedReferences.contains(refObj)){
			fieldValue = '';
			if(refObj == 'User' && field.getName() == 'OwnerId'){
				fieldValue = user.Id;
			} else if( refObj == 'Profile' ){
				fieldValue = profile.Id;
			}
		} else if(refObj == 'RecordType'){
			fieldValue = getRecordType(sObjectType);
		} else if(createReferences) {
			SObject refRecord = createFullObject(refObj, false, false);
			System.debug('Adding Reference Record: '+refObj);
			insert refRecord;
			fieldValue = refRecord.Id;
		}
		return fieldValue;
	}

	/**
	 * Get a record type ID for the specified SObject
	 * @param  sObjectType sObject API Name
	 * @return             ID of Random Availabe/Active Record Type
	 */
	private static String getRecordType(String sObjectType){
		List<Schema.RecordTypeInfo> recordTypes = globalDescribeMap.get(sObjectType).getDescribe().getRecordTypeInfos();
		String recordTypeId;
		if(recordTypes.size() > 1){
			List<String> availableRecordTypes = new List<String>();
			for(Schema.RecordTypeInfo recordTypeDetail : recordTypes){
				if(recordTypeDetail.isAvailable()){
					availableRecordTypes.add(recordTypeDetail.getRecordTypeId());
				}
			}
			recordTypeId = availableRecordTypes[getRandomInteger(availableRecordTypes.size())];
		} else {
			recordTypeId = recordTypes[0].getRecordTypeId();
		}

		return recordTypeId;
	}
}