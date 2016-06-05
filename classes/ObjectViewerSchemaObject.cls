/**
 * オブジェクトのスキーマ情報
 */
public class ObjectViewerSchemaObject implements Comparable {
	public static final Integer OBJ_TYPE_STANDARD = 0;
	public static final Integer OBJ_TYPE_CUSTOM = 1;
	public static final Integer OBJ_TYPE_ETC = 2;

	public static final String SORT_ORDER_ASCENDING = 'asc';
	public static final String SORT_ORDER_DESCENDING = 'desc';

	public String sortOrder {get; set;}
	public String sortField {get; set;}

	public Integer objType {get; set;}

	public String key {get; set;}
	public String label {get; set;}
	public String name {get; set;}
	public String prefix {get; set;}

	public ObjectViewerSchemaObject(){
		this.sortOrder = SORT_ORDER_ASCENDING;
		this.sortField = 'label';

		this.objType = OBJ_TYPE_STANDARD;
		this.key = '';
		this.label = '';
		this.name = '';
		this.prefix = '';
	}

	public Integer compareTo(Object compareTo){
		ObjectViewerSchemaObject compareToInfo = (ObjectViewerSchemaObject)compareTo;
		if(String.isEmpty(sortField)){
			return 0;
		}

		Object cmp1 = null;
		Object cmp2 = null;
		if(sortField.equals('label')){
			cmp1 = label;
			cmp2 = compareToInfo.label;
		}
		else if(sortField.equals('name')){
			cmp1 = name;
			cmp2 = compareToInfo.name;
		}
		else if(sortField.equals('prefix')){
			cmp1 = prefix;
			cmp2 = compareToInfo.prefix;
		}
		else{
			return 0;
		}

		if((String)cmp1 > (String)cmp2){
			return sortOrder.equals(SORT_ORDER_ASCENDING) ? 1 : -1;
		}
		if((String)cmp1 < (String)cmp2){
			return sortOrder.equals(SORT_ORDER_ASCENDING) ? -1 : 1;
		}
		return 0;
	}
}