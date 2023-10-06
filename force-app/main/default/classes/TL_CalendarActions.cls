public with sharing class TL_CalendarActions {
  private static String api = 'https://www.googleapis.com/calendar/v3';

  public static Object[] ListCalendars(Google_Token__c token){
    String endPoint = api+'/users/me/calendarList?minAccessRole=owner';
    HttpResponse res = TL_GoogleApiCalls.preCallGoogleApi(endPoint, 'GET', null, true, token);
    if(Test.isRunningTest()) return calendarsMock;
    Map<String, Object> result = (Map<String, Object>)JSON.deserializeUntyped(res.getBody());
    return (Object[])result.get('items');
  }

  @Future(callout=true)
  public static void syncCalendars(String tokenId){
    Google_Token__c token = [SELECT Id, Access_Token__c, Refresh_Token__c FROM Google_Token__c WHERE Id = :tokenId];
    Object[] calendarsGO = ListCalendars(token);
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
      if(calendarSFMap.get(id) != null) continue;
      GoogleCalendar__c newCalendar = new GoogleCalendar__c(GoogleId__c=id, Name=title, GoogleToken__c=token.Id);
      if (isDefault != null && calendarSFMap.get('Default') == null) newCalendar.Default__c = isDefault;
      toInsert.add(newCalendar);
    }
    insert toInsert;
  }
  
  @InvocableMethod
  public static void syncCalendarsInvocable(Google_Token__c[] tokens){
    for(Google_Token__c token: tokens) syncCalendars(token.Id);
  }

  public class ErrorException extends Exception {}
  private static List<Object> calendarsMock = new List<Object> { new Map<String, Object> {'id' => 'testId','summary' => 'testSummary','primary' => true } };
}