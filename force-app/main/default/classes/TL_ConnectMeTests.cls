@isTest
public class TL_ConnectMeTests {
  @testSetup
  static void setup(){
    Google_Token__c token = new Google_Token__c(Name='test token', Email__c='test@test.com');
    insert token;
    GoogleCalendar__c calendar = new GoogleCalendar__c(GoogleId__c='calendarId', Default__c=true, GoogleToken__c=token.Id);
    insert new List<SObject>{ calendar };
  }

  @isTest
  static void connectorController(){
    GenericConnectorController controller = new GenericConnectorController();
    PageReference pr = controller.doGetAuthorizationCode();
    pr = controller.doGetAccessToken();
    Google_Token__c token = [SELECT Id, Refresh_Token__c FROM Google_Token__c LIMIT 1];
    GenericConnectorController.doRefreshTokenStatic(token);
  }

  @isTest
  static void calendarActions(){
    Google_Token__c token = [SELECT Id, Refresh_Token__c FROM Google_Token__c LIMIT 1];
    TL_CalendarActions.syncCalendars(token);
  }

  @isTest
  static void apiCall_Test(){
    Google_Token__c token = [SELECT Id, Refresh_Token__c FROM Google_Token__c LIMIT 1];
    try {
      TL_GoogleApiCalls.callGoogleApi('endpoint', 'GET', 'null', true, token);
    } catch (Exception e) {}
  }

  @isTest
  static void event_Test(){
    Google_Token__c token = [SELECT Id, Refresh_Token__c FROM Google_Token__c LIMIT 1];
    Datetime start = Datetime.now();
    TL_EventActions.createEvent('calendar', 'title', start, start.addHours(1), token);
    TL_EventActions.deleteEvent('eventId', 'calendarId', token);
    TL_EventActions.getCommingEvents('calendar', token);
    TL_EventActions.getSpecificEvent('calendarId', 'eventId', token);
    TL_EventActions.listEvents('calendar', token);
    TL_EventActions.sendUpdateEvent('body', 'calendarId', 'eventId', token);
  }

  @isTest
  static void seat_Test(){
    Google_Token__c token = [SELECT Id, Refresh_Token__c FROM Google_Token__c LIMIT 1];
    Datetime start = Datetime.now();
    TL_SeatActions.addGuestToEvent('eventId', 'calendarId', new List<String>{ 'newGuestEmail@gmail.com' }, token);
  }
}