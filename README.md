# Test Data Factory
Salesforce.com Unit Testing Data Factory

# Example Usage
Method definition:
`public static SObject createFullObject(String sObjectType, Boolean fillOnlyRequired, Boolean createReferences)`

`String sObjectType`: API Name of the Object to Create

`fillOnlyRequired`: If `TRUE` only the required fields on the sObject will be prepopulated. If `FALSE` All user accessible/createable fields will prepopulated

`createReferences`: If `TRUE` any identified Lookup fields will have their respective parent record generated for them. For example, if you create a Contact with
`createReferences`=`TRUE`, the Account record will also be generated.


To create an Account with all fields populated and parent records:

`DataWizFactory.createFullObject('Account', **false**, true);`

To create an Account with **REQUIRED FIELDS ONLY**, and parent records:

`DataWizFactory.createFullObject('Account', **true**, true);`

To create an Account with all fields populated and **no parent records**:

`DataWizFactory.createFullObject('Account', false, **true**);`

Main method for creating records:

`public static SObject createFullObject(String sObjectType, Boolean fillOnlyRequired, Boolean createReferences)`


**Params**

`fillOnlyRequired` Set to TRUE if you want to populate only REQUIRED fields.

`createReferences` Set to TRUE if you want to create related reference records on lookup fields.