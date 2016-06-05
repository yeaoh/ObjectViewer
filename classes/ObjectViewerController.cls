public with sharing class ObjectViewerController {
	/**
	 * データ型の日本語化テーブル
	 * ※他の設定値とあわせて判定するデータ型もある
	 */
	private Map<Schema.DisplayType, String> typeLabelMap = new Map<Schema.DisplayType, String>{
		Schema.DisplayType.Id => 'ID',
		Schema.DisplayType.URL => 'URL',
		Schema.DisplayType.String => 'テキスト',
		Schema.DisplayType.TextArea => 'テキストエリア',
		Schema.DisplayType.Combobox => 'テキスト(+選択リスト)',
		Schema.DisplayType.EncryptedString => 'テキスト(暗号化)',
		Schema.DisplayType.base64 => 'Base64',
		Schema.DisplayType.Boolean => 'チェックボックス',
		Schema.DisplayType.Phone => '電話',
		Schema.DisplayType.Email => '電子メール',
		Schema.DisplayType.Date => '日付',
		Schema.DisplayType.DateTime => '日付/時間',
		Schema.DisplayType.Integer => '数値',
		Schema.DisplayType.Double => '数値',
		Schema.DisplayType.Percent => 'パーセント',
		Schema.DisplayType.Currency => '通貨',
		Schema.DisplayType.Picklist => '選択リスト',
		Schema.DisplayType.MultiPicklist => '選択リスト (複数選択)',
		Schema.DisplayType.Reference => '参照関係'
	};

	/** 標準オブジェクトとするオブジェクトのAPI参照名(EclipseのObjects - Standardを元に作成) */
	private Set<String> standardObjectNames = new Set<String> {
		'Account', 
		'AccountContactRole', 
		'Activity', 
		'Asset', 
		'Campaign', 
		'CampaignMember', 
		'Case', 
		'CaseContactRole', 
		'Contact', 
		'ContentVersion', 
		'Contract', 
		'ContractContactRole', 
		'DuplicateRecordItem', 
		'DuplicateRecordSet', 
		'Event', 
		'FeedItem', 
		'ForecastingCategoryMapping', 
		'Idea', 
		'Lead', 
		'Macro', 
		'MacroAction', 
		'MacroInstruction', 
		'Opportunity', 
		'OpportunityCompetitor', 
		'OpportunityContactRole', 
		'OpportunityLineItem', 
		'PartnerRole', 
		'Pricebook2', 
		'PricebookEntry', 
		'Product2', 
		'Site', 
		'SocialPersona', 
		'Solution', 
		'StreamingChannel', 
		'Task', 
		'User', 
		'UserProvisioningRequest'
	};

	/** 標準タブに表示するオブジェクト情報 */
	public List<ObjectViewerSchemaObject> standardObjects {get; set;}
	/** カスタムタブに表示するオブジェクト情報 */
	public List<ObjectViewerSchemaObject> customObjects {get; set;}
	/** 標準・カスタム以外タブに表示するオブジェクト情報 */
	public List<ObjectViewerSchemaObject> etcObjects {get; set;}

	/** 項目ページに表示するオブジェクト情報 */
	public ObjectViewerSchemaObject selectedObject {get; set;}
	/** 項目情報 */
	public List<ObjectViewerSchemaField> schemaFields {get; set;}
	/** 被参照オブジェクト情報 */
	public List<ObjectViewerSchemaChildRelation> childRelationships {get; set;}

	/** クエリ */
	public String queryText {get; set;}

	/**
	 * コンストラクタ
	 */
	public ObjectViewerController() {
	}

	/**
	 * オブジェクト一覧の表示
	 */
	public PageReference doViewObjectList(){
		try{
			getObjectInfos();
			return null;
		}
		catch(Exception e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'システムエラー'));
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
			return null;
		}
	}

	/**
	 * 項目一覧の表示
	 */
	public PageReference doViewFieldList(){
		try{
			String objName = ApexPages.currentPage().getParameters().get('key');
			if(String.isEmpty(objName)){
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'パラメータエラー'));
				return null;
			}

			getSelectedObjectInfo(objName);
			getFieldInfo(objName);
			getChildRelationships(objName);

			return null;
		}
		catch(Exception e){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'システムエラー'));
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
			return null;
		}
	}

	/**
	 * 選択されたオブジェクト情報の取得
	 * @param objName オブジェクトのAPI参照名
	 */
	private void getSelectedObjectInfo(String objName){
		Schema.DescribeSObjectResult objRet = Schema.getGlobalDescribe().get(objName).getDescribe();

		ObjectViewerSchemaObject obj = new ObjectViewerSchemaObject();
		obj = getObjectInfo(objRet);

		this.selectedObject = obj;
	}

	/**
	 * オブジェクトの情報の取得
	 */
	private void getObjectInfos(){
		this.standardObjects = new List<ObjectViewerSchemaObject>();
		this.customObjects = new List<ObjectViewerSchemaObject>();
		this.etcObjects = new List<ObjectViewerSchemaObject>();

		Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
		for(String gdKey : gd.keySet()) {
			Schema.SObjectType objType = gd.get(gdKey);
			Schema.DescribeSObjectResult objRet = objType.getDescribe();

			ObjectViewerSchemaObject obj = new ObjectViewerSchemaObject();
			obj = getObjectInfo(objRet);

			// カスタムオブジェクト
			if(objRet.isCustom()){
				obj.objType = ObjectViewerSchemaObject.OBJ_TYPE_CUSTOM;
				this.customObjects.add(obj);
			}
			else{
				// 標準オブジェクト
				if(this.standardObjectNames.contains(obj.name)){
					obj.objType = ObjectViewerSchemaObject.OBJ_TYPE_STANDARD;
					this.standardObjects.add(obj);
				}
				// その他(システム系、履歴、フィードなど)
				else{
					obj.objType = ObjectViewerSchemaObject.OBJ_TYPE_ETC;
					this.etcObjects.add(obj);
				}
			}
		}

		// ソート
		this.standardObjects.sort();
		this.customObjects.sort();
		this.etcObjects.sort();

		return;
	}

	/**
	 * オブジェクトの情報の取得
	 */
	private ObjectViewerSchemaObject getObjectInfo(Schema.DescribeSObjectResult objRet){
		ObjectViewerSchemaObject obj = new ObjectViewerSchemaObject();
		obj.key = objRet.getName();
		obj.label = objRet.getLabel();
		obj.name = objRet.getName();
		obj.prefix = objRet.getKeyPrefix();

		return obj;
	}

	/**
	 * 項目の情報取得
	 */
	private void getFieldInfo(String objName){
		this.schemaFields = new List<ObjectViewerSchemaField>();

		Map<String, Schema.SObjectField> fmap = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap();
		for(Schema.SObjectField f : fmap.values()) {
			Schema.DescribeFieldResult fd = f.getDescribe();

			ObjectViewerSchemaField field = new ObjectViewerSchemaField();
			field.label = fd.getLabel();
			field.name = fd.getName();

			Schema.DisplayType fieldType = fd.getType();
			field.typeLabel = getFieldTypeLabel(fd, fieldType);
			field.references = getReferences(fd, fieldType);
			field.referencesForCsv = getReferencesForCsv(field.references);
			field.length = getFieldLength(fd, fieldType);
			field.picklistValues = getPicklistValues(fd, fieldType);
			field.picklistValuesForCsv = getPicklistValuesForCsv(field.picklistValues);
			field.formula = fd.getCalculatedFormula();
			field.formulaForCsv = String.isNotEmpty(field.formula) ? field.formula.escapeCsv() : field.formula;
			field.custom = fd.isCustom();
			field.nillable = fd.isNillable();

			this.schemaFields.add(field);
		}
	}

	/**
	 * データ型のラベルを取得
	 * @param fd 項目情報
	 * @param fieldType データ型の項目値
	 */
	private String getFieldTypeLabel(Schema.DescribeFieldResult fd, Schema.DisplayType fieldType){
		String typeLabel = typeLabelMap.get(fieldType);

		if(fd.isCalculated()){
			if(String.isNotEmpty(fd.getCalculatedFormula())){
				typeLabel = '数式 (' + typeLabel + ')';
			}
			else{
				typeLabel = '積み上げ集計 (' + typeLabel + ')';
			}
		}

		if(fieldType == Schema.DisplayType.Reference && fd.isCascadeDelete()){
			typeLabel = '主従関係';
		}

		if(fieldType == Schema.DisplayType.String){
			if(fd.isAutoNumber()){
				typeLabel = '自動採番';
			}
			else if(String.isNotEmpty(fd.getRelationshipName())){
				typeLabel = '外部参照';
			}
		}

		if(fieldType == Schema.DisplayType.TextArea){
			if(fd.getLength() > 255){
				typeLabel = 'ロングテキストエリア';
			}
			else if(fd.isHtmlFormatted()){
				typeLabel = 'リッチテキストエリア';
			}
		}

		if(String.isEmpty(typeLabel)){
			typeLabel = fieldType.name();
			if(typeLabel == 'ADDRESS'){
				typeLabel = '住所';
			}
			else if(typeLabel == 'LOCATION'){
				typeLabel = '地理位置情報';
			}
		}

		return typeLabel;
	}

	/**
	 * 参照先オブジェクトを取得
	 * @param fd 項目情報
	 * @param fieldType データ型の項目値
	 */
	private List<Map<String, String> > getReferences(Schema.DescribeFieldResult fd, Schema.DisplayType fieldType){
		List<Map<String, String> > references = new List<Map<String, String> >();
		List<Schema.SObjectType> referenceTos = fd.getReferenceTo();
		for(Schema.SObjectType referenceTo : referenceTos){
			Map<String, String> m = new Map<String, String>();
			m.put('name', referenceTo.getDescribe().getName());
			m.put('label', referenceTo.getDescribe().getLabel());
			references.add(m);
		}
		return references;
	}

	/**
	 * 参照先オブジェクト(CSV用)を取得
	 * @param references 参照先オブジェクトのリスト
	 */
	private String getReferencesForCsv(List<Map<String, String> > references){
		String referencesForCsv = '';
		for(Map<String, String> reference : references){
			if(String.isNotEmpty(referencesForCsv)){
				referencesForCsv += '\n';
			}
			referencesForCsv += reference.get('label');
		}
		return referencesForCsv;
	}

	/**
	 * 桁数を取得
	 * @param fd 項目情報
	 * @param fieldType データ型の項目値
	 */
	private String getFieldLength(Schema.DescribeFieldResult fd, Schema.DisplayType fieldType){
		String length = '';
		if(fieldType == Schema.DisplayType.String || fieldType == Schema.DisplayType.TextArea || fieldType == Schema.DisplayType.EncryptedString){
			length = String.valueOf(fd.getLength());
		}
		else if(fieldType == Schema.DisplayType.Double || fieldType == Schema.DisplayType.Percent || fieldType == Schema.DisplayType.Currency){
			length = String.valueOf(fd.getPrecision() - fd.getScale()) + ',' + String.valueOf(fd.getScale());
		}
		else if(fieldType == Schema.DisplayType.Integer){
			length = String.valueOf(fd.getDigits() + ',0');
		}
		return length;
	}

	/**
	 * 選択リスト値を取得
	 * @param fd 項目情報
	 * @param fieldType データ型の項目値
	 */
	private List<String> getPicklistValues(Schema.DescribeFieldResult fd, Schema.DisplayType fieldType){
		List<String> picklistValues = new List<String>();
		if(fieldType == Schema.DisplayType.Picklist || fieldType == Schema.DisplayType.MultiPicklist){
			List<Schema.PicklistEntry> picklistEntries = fd.getPicklistValues();
			for(Schema.PicklistEntry picklistEntry : picklistEntries){
				picklistValues.add(picklistEntry.getValue());
			}
		}
		return picklistValues;
	}

	/**
	 * 選択リスト値(CSV用)を取得
	 * @param picklistValues 選択リスト値のリスト
	 */
	private String getPicklistValuesForCsv(List<String> picklistValues){
		String picklistValuesForCsv = '';
		for(String picklistValue : picklistValues){
			if(String.isNotEmpty(picklistValuesForCsv)){
				picklistValuesForCsv += '\n';
			}
			picklistValuesForCsv += picklistValue;
		}
		return picklistValuesForCsv;
	}

	/**
	 * 被参照オブジェクト取得
	 */
	private void getChildRelationships(String objName){
		this.childRelationships = new List<ObjectViewerSchemaChildRelation>();

		for(Schema.ChildRelationship cr : Schema.getGlobalDescribe().get(objName).getDescribe().getChildRelationships()) {
			ObjectViewerSchemaChildRelation crInfo = new ObjectViewerSchemaChildRelation();
			crInfo.relationshipName = cr.getRelationshipName();
			crInfo.objectName = cr.getChildSObject().getDescribe().getName();
			crInfo.objectLabel = cr.getChildSObject().getDescribe().getLabel();
			crInfo.fieldName = cr.getField().getDescribe().getName();
			crInfo.fieldLabel = cr.getField().getDescribe().getLabel();

			this.childRelationships.add(crInfo);
		}
	}

	/**
	 * クエリ生成
	 */
	public PageReference doGenerateQuery(){
		this.queryText = generateQuery();
		return null;
	}

	/**
	 * クエリ生成
	 */
	public String generateQuery(){
		final String INDENT = '    ';
		String queryText = '';
		for(ObjectViewerSchemaField schemaField : schemaFields){
			if(!schemaField.selected){
				continue;
			}

			queryText += INDENT + schemaField.name + ',' + '\n';
		}

		// 最後のカンマを削除
		queryText = queryText.substringBeforeLast(',') + '\n';

		if(String.isNotEmpty(queryText)){
			queryText  = 'SELECT \n' + queryText;
			queryText += 'FROM \n';
			queryText += INDENT + selectedObject.name + '\n';
		}

		return queryText;
	}

	/**
	 * 項目のスキーマ情報
	 */
	private class ObjectViewerSchemaField {
		public Boolean selected {get; set;}
		public String label {get; set;}
		public String name {get; set;}
		public String typeLabel {get; set;}
		public List<Map<String, String> > references {get; set;}
		public String referencesForCsv {get; set;}
		public String length {get; set;}
		public List<String> picklistValues {get; set;}
		public String picklistValuesForCsv {get; set;}
		public String formula {get; set;}
		public String formulaForCsv {get; set;}
		public Boolean custom {get; set;}
		public Boolean nillable {get; set;}

		public ObjectViewerSchemaField(){
			this.selected = false;
			this.label = '';
			this.name = '';
			this.typeLabel = '';
			this.references = new List<Map<String, String> >();
			this.referencesForCsv = '';
			this.length = '';
			this.picklistValues = new List<String>();
			this.picklistValuesForCsv = '';
			this.formula = '';
			this.formulaForCsv = '';
			this.custom = false;
			this.nillable = false;
		}
	}

	/**
	 * 被参照オブジェクトのスキーマ情報
	 */
	private class ObjectViewerSchemaChildRelation {
		public String relationshipName {get; set;}
		public String objectName {get; set;}
		public String objectLabel {get; set;}
		public String fieldName {get; set;}
		public String fieldLabel {get; set;}

		public ObjectViewerSchemaChildRelation() {
			this.relationshipName = '';
			this.objectName = '';
			this.objectLabel = '';
			this.fieldName = '';
			this.fieldLabel = '';
		}
	}
}