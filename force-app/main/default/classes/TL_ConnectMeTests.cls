@isTest
public class TL_ConnectMeTests {
  @testSetup
  static void setup(){
    GoogleCalendar__c calendar = new GoogleCalendar__c(GoogleId__c='calendarId', Default__c=true);
    insert new List<SObject>{ calendar };
  }

  @isTest
  static void connectorController(){
    GenericConnectorController controller = new GenericConnectorController();
    PageReference pr = controller.doGetAuthorizationCode();
    pr = controller.doGetAccessToken();
    controller.doRefreshToken();
  }

  @isTest
  static void calendarActions(){
    TL_CalendarActions.syncCalendars();
  }
}