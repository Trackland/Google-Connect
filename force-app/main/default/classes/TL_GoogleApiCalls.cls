public with sharing class TL_GoogleApiCalls {
  
  public static HttpResponse callGoogleApiFromHttp(String endpoint, String method, String body, HttpRequest httpReq, boolean first, Google_Token__c googleToken){
    httpReq.setEndpoint(endpoint);
    httpReq.setMethod(method);
    if(body != null) httpReq.setBody(body);

    Http http = new Http();
    HttpResponse res;
    if(!Test.isRunningTest()) res = http.send(httpReq);
    else {
      res = new HttpResponse();
      res.setStatus('401');
      res.setStatusCode(400);
      res.setBody(body);
    }

    // if(res.getStatusCode() == 401 && first) {
    //   Google_Token__c token = GenericConnectorController.doRefreshTokenStatic(googleToken);
    //   httpReq.setHeader('Authorization','Bearer '+token.Access_Token__c);
    //   if(!Test.isRunningTest()) res = http.send(httpReq);
    //   update token;
    // }

    apiError(res);
    return res;
  }

  public static HttpResponse callGoogleApi(String endpoint, String method, String body, Boolean first, Google_Token__c token){
    HttpRequest httpReq = new HttpRequest();
    httpReq.setHeader('Content-Type', 'application/json');
    httpReq.setHeader('Authorization','Bearer '+token.Access_Token__c);
    return callGoogleApiFromHttp(endpoint, method, body, httpReq, first, token);
  }

  public static void apiError(HttpResponse res){
    if(res.getStatusCode() == 200) return;
    String errorMessage = 'Unexpected Error while communicating with Google Calendar API. Status ';
    errorMessage += res.getStatus();
    errorMessage += ' and Status Code ';
    errorMessage += res.getStatuscode();
    errorMessage += ' '+res.getBody();
    if(res.getStatusCode() == 401) errorMessage = 'Refresh token is necesary';
    throw new ErrorException(errorMessage);
  }

  public static HttpResponse preCallGoogleApi(String endpoint, String method, String body, Boolean first, Google_Token__c token){
    if(!Test.isRunningTest()) return callGoogleApi(endpoint, method, body, first, token);
    HttpResponse res = new HttpResponse();
    res.setStatus('200');
    res.setStatusCode(200);
    res.setBody('{}');
    return res;
  }

  public class ErrorException extends Exception {}
}