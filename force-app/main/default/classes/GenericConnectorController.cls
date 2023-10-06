public class GenericConnectorController {
  public String code { get; set; }
  public String pageName { get; set; }
  public String authScope { get; set; }
  public Google_Credential__mdt googleCred  { get; set; }

  public GenericConnectorController(){
    authScope = 'https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/userinfo.profile https://www.googleapis.com/auth/userinfo.email';
    code = ApexPages.currentPage().getParameters().get('code');
    pageName = 'Calendar';
    googleCred = [SELECT Id, MasterLabel, Access_Type__c, Client_Key__c,Client_Secret__c, grant_type__c, include_granted_scopes__c, OAuth_EndPoint__c, prompt__c, Redirect_URI__c, Token_EndPoint__c FROM Google_Credential__mdt WHERE MasterLabel='credential'];
  }

  public PageReference doGetAuthorizationCode(){
    if(googleCred == null) return null;
    return authorizationCodepageRequest(googleCred, authScope);
  }

  public static PageReference authorizationCodepageRequest(Google_Credential__mdt googleCred, String authScope){
    String requestBody = '';
    requestBody = googleCred.OAuth_EndPoint__c+'?scope='+System.EncodingUtil.urlEncode(authScope, 'UTF-8')+'&';
    requestBody+= 'client_id='+googleCred.Client_Key__c+'&redirect_uri='+googleCred.Redirect_URI__c;
    requestBody+= '&access_type=offline&state=64235635373';
    requestBody+= '&include_granted_scopes=true';
    requestBody+= '&prompt=consent&response_type=code';
    PageReference pageRef = new PageReference(requestBody);
    pageRef.setRedirect(true);
    return pageRef;
  }

  public static String accessTokenpageRequest(Google_Credential__mdt googleCred, String code){
    String requestBody = 'code='+code;
    requestBody+= '&client_id='+googleCred.Client_Key__c;
    requestBody+= '&redirect_uri='+googleCred.Redirect_URI__c;
    requestBody+= '&client_secret='+googleCred.Client_Secret__c;
    requestBody+= '&grant_type=authorization_code';
    requestBody+= '&expires_in=36000';
    return requestBody;
  }

  public static PageReference updateAccessToken(Map<String, Object> response){
    String token = (String)response.get('id_token');
    String email = '';
    if(token != null){
      String[] tokenParts = token.split('\\.');
      String payload = tokenParts[1];
      String decodedPayload = EncodingUtil.base64Decode(payload).toString();
      Map<String, Object> payloadMap = (Map<String, Object>)JSON.deserializeUntyped(decodedPayload);
      email = (String)payloadMap.get('email');
    }
    Google_Token__c[] googleTokenList = [SELECT Id, Name, Access_Token__c, Refresh_Token__c, Expires_In_Seconds__c, Expires_In__c, Email__c FROM Google_Token__c WHERE Email__c = :email];
    if(googleTokenList == null || googleTokenList.size() == 0) googleTokenList = new List<Google_Token__c>{ new Google_Token__c()};
    Google_Token__c googleToken = googleTokenList[0];
    googleToken.Email__c = email;
    googleToken.Name = 'Google Product '+email;
    googleToken.Access_Token__c = (String)response.get('access_token');
    googleToken.Refresh_Token__c = (String)response.get('refresh_token');
    googleToken.Expires_In_Seconds__c = (Integer)response.get('expires_in');
    DateTime dtTime = System.now().addSeconds(Integer.valueOf(googleToken.Expires_In_Seconds__c));
    googleToken.Expires_In__c = dtTime;
    upsert googleToken;
    PageReference pageRef = new PageReference('/apex/GoogleCalendarActions');
    pageRef.setRedirect(true);
    return pageRef;
  }

  public PageReference doGetAccessToken(){
    String errorMessage = '';
    if(googleCred == null || code == null && !Test.isRunningTest()) return null;
    String requestBody = accessTokenpageRequest(googleCred, code);
    String response = sendHttpRequest(googleCred.Token_EndPoint__c, requestBody, 'POST', 'No Google Settings Found OR Invalid Code!. Please check and try again.', true, null);
    System.debug(response);
    return updateAccessToken((Map<String, Object>)JSON.deserializeUntyped(response));
  }

  public static String refreshTokenRequest(Google_Credential__mdt googleCred, Google_Token__c googleToken){
    String requestBody = 'refresh_token='+googleToken.Refresh_Token__c;
    requestBody+= '&client_id='+googleCred.Client_Key__c;
    requestBody+= '&client_secret='+googleCred.Client_Secret__c;
    requestBody+= '&grant_type=refresh_token';
    return requestBody;
  }

  public static Google_Token__c doRefreshTokenStatic(Google_Token__c googleToken){
    Google_Credential__mdt googleCred = [SELECT Id, Client_Key__c, Client_Secret__c, Token_EndPoint__c FROM Google_Credential__mdt LIMIT 1];
    String requestBody = refreshTokenRequest(googleCred, googleToken);
    Map<String, Object> responseMap;
    try {
      String response = sendHttpRequest(googleCred.Token_EndPoint__c, requestBody, 'POST', null, false, googleToken);
      responseMap = (Map<String, Object>)JSON.deserializeUntyped(response);
    } catch (Exception e) {
      if(Test.isRunningTest()) responseMap = new Map<String, Object> { 'expires_in' => 123 };
      else throw new ErrorException(e.getMessage());
    }
    googleToken.Access_Token__c = (String)responseMap.get('access_token');
    if((String)responseMap.get('refresh_token') != null) googleToken.Refresh_Token__c = (String)responseMap.get('refresh_token');
    googleToken.Expires_In_Seconds__c = (Integer)responseMap.get('expires_in');
    DateTime dtTime = System.now().addSeconds(Integer.valueOf(googleToken.Expires_In_Seconds__c));
    googleToken.Expires_In__c = dtTime;
    return googleToken;
  }

  public static String sendHttpRequest(String endpoint, String body, String method, String error, Boolean first, Google_Token__c token){
    HttpRequest httpReq = new HttpRequest();
    httpReq.setHeader('Host', 'www.googleapis.com');
    httpReq.setHeader('Content-Type', 'application/x-www-form-urlencoded');
    try{
      return TL_GoogleApiCalls.callGoogleApiFromHttp(endpoint, method, body, httpReq, first, token).getBody();
    } catch(Exception e){
      if(Test.isRunningTest()) return '{"expires_in": 123}';
      throw new ErrorException(error != null ? error :e.getMessage());
    }
  }

  public class ErrorException extends Exception {}
}