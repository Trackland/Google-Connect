public with sharing class TL_CalendarActions {
  private static String api = 'https://www.googleapis.com/calendar/v3';

  public static Object[] ListCalendars(){
    String endPoint = api+'/users/me/calendarList?minAccessRole=owner';
    if(Test.isRunningTest()) return calendarsMock;
    HttpResponse res = TL_GoogleApiCalls.callGoogleApi(endPoint, 'GET', null, true);
    Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
    return (Object[])result.get('items');
  }

  @InvocableMethod
  public static void syncCalendars(){
    Object[] calendarsGO = ListCalendars();
    List<Map<String, Object>> calendarsG = new List<Map<String, Object>>();
    String[] googleIds = new List<String>();
    for(Object calendarO: calendarsGO){
      Map<String, Object> calendar = (Map<String, Object>) calendarO;
      calendarsG.add(calendar);
      googleIds.add((String) calendar.get('id'));
    }
    calendarsGO = null;
    GoogleCalendar__c[] calendarsSF = [SELECT GoogleId__c, Default__c FROM GoogleCalendar__c WHERE GoogleId__c in :googleIds];
    Map<String, Boolean> calendarSFMap = new Map<String, Boolean>();
    for(GoogleCalendar__c calendar: calendarsSF) {
      calendarSFMap.put(calendar.GoogleId__c, true);
      if(calendar.Default__c) calendarSFMap.put('Default', true);
    }
    GoogleCalendar__c[] toInsert = new List<GoogleCalendar__c>();
    for(Map<String, Object> calendar: calendarsG){
      String id = (String)calendar.get('id');
      String title = (String)calendar.get('summary');
      Boolean isDefault = (Boolean)calendar.get('primary');
      // String description = (String)calendar.get('description');
      if(calendarSFMap.get(id) != null) continue;
      GoogleCalendar__c newCalendar = new GoogleCalendar__c(GoogleId__c=id, Name=title);
      if (isDefault != null && calendarSFMap.get('Default') == null) newCalendar.Default__c = isDefault;
      toInsert.add(newCalendar);
    }
    insert toInsert;
  }

  public class ErrorException extends Exception {}
  private static List<Object> calendarsMock = new List<Object> { new Map<String, Object> {'id' => 'testId','summary' => 'testSummary','primary' => true } };
}