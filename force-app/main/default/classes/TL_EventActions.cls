public class TL_EventActions {
  private static String api = 'https://www.googleapis.com/calendar/v3';

  public static void deleteEvent(String eventId, String calendarId, Google_Token__c token){
    String endPoint = api+'/calendars/'+calendarId+'/events/'+eventId;
    TL_GoogleApiCalls.preCallGoogleApi(endPoint, 'DELETE', '', true, token);
  }

  public static String createEvent(String calendarId, String title, Datetime start, Datetime endT, Google_Token__c token){
    String endPoint = api+'/calendars/'+calendarId+'/events?sendUpdates=all';
    if(endT == null) endT = start.addHours(2);
    Map<String, Object> bodyMap = new Map<String, Object>{
      'end' => new Map<String, String>{
        'dateTime' => endT.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''),
        'timeZone' => UserInfo.getTimeZone().getID()
      },
      'reminders' => '{"useDefault": true}',
      'start' => new Map<String, String>{
        'dateTime' => start.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''),
        'timeZone' => UserInfo.getTimeZone().getID()
      },
      'summary' => title,
      'status' => 'confirmed'
    };
    
    return TL_GoogleApiCalls.preCallGoogleApi(endPoint, 'POST', JSON.serialize(bodyMap), true, token).getBody();
  }

  public static Map<String, Object> getSpecificEvent(String calendarId, String eventId, Google_Token__c token){
    String endpoint = api+'/calendars/'+calendarId+'/events/'+eventId;
    HttpResponse res = TL_GoogleApiCalls.preCallGoogleApi(endPoint, 'GET', null, true, token);
    return (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
  }

  public static void sendUpdateEvent(String body, String calendarId, String eventId, Google_Token__c token){
    String endpoint = api+'/calendars/'+calendarId+'/events/'+eventId;
    HttpResponse res = TL_GoogleApiCalls.preCallGoogleApi(endPoint, 'PUT', body, true, token);
  }

  public static Object getCommingEvents(String calendarId, Google_Token__c token){
    String timeMin = Datetime.now().addDays(-1).formatGMT('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
    String endPoint = api+'/calendars/'+calendarId+'/events/';
    endPoint += '?timeMin=' + EncodingUtil.urlEncode(timeMin, 'UTF-8') + '&singleEvents=true&orderBy=startTime';
    if(Test.isRunningTest()) return eventsMock;
    System.debug(endPoint);
    HttpResponse res = TL_GoogleApiCalls.preCallGoogleApi(endPoint, 'GET', null, true, token);
    return JSON.deserializeUntyped(res.getBody());
  } 

  public static Object listEvents(String calendar, Google_Token__c token){
    String endPoint = api+'/calendars/'+calendar+'/events';
    HttpResponse res = TL_GoogleApiCalls.preCallGoogleApi(endPoint, 'GET', null, true, token);
    return JSON.deserializeUntyped(res.getBody());
  }

  public class ErrorException extends Exception {}
  private static Map<String, Object> eventsMock = new Map<String, Object> { 'items' => new List<Object> { new Map<String, Object> { 'id' => 'eventId', 'attendees' => new List<Object> { new Map<string, Object> { 'email' => 'test@test.com', 'responseStatus' => 'yes'} }}}};
}