public class TL_SeatActions {
  private static String api = 'https://www.googleapis.com/calendar/v3';

  public static void addGuestToEvent(String eventId, String calendarId, String[] newGuestEmails, Google_Token__c token){
    String endPoint = api+'/calendars/'+calendarId+'/events/'+eventId+'?sendUpdates=all';
    Map<String, Object> eventMap = TL_EventActions.getSpecificEvent(calendarId, eventId, token);
    Object[] attendees = new List<Object>();
    if(eventMap.get('attendees') != null) attendees = (Object[]) eventMap.get('attendees');
    String[] existingGuestEmails = new List<String>();
    for(Object attendee : attendees) existingGuestEmails.add((String) ((Map<String, Object>) attendee).get('email'));
    for(String newGuestEmail : newGuestEmails){
      if(existingGuestEmails.contains(newGuestEmail)) continue;
      attendees.add(new Map<String, Object>{
        'email' => newGuestEmail
      });
    }
    eventMap.put('attendees', attendees);
    String body = JSON.serialize(eventMap);
    HttpResponse res = TL_GoogleApiCalls.preCallGoogleApi(endPoint, 'PUT', body, true, token);
  }

  public class ErrorException extends Exception {}
}