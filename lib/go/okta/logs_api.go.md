type OktaLog struct {
    Action          string `json:"action"`
    Actor           struct {
        id          string `json:"id"`
        displayName string `json:"displayName"`
    } `json:"actor"`
    authenticationContext struct {
        authenticationProvider string `json:"authenticationProvider"`
        authenticationStep    int    `json:"authenticationStep"`
        callerIp              string `json:"callerIp"`
        fingerprint           struct {
            deviceFingerprinting bool   `json:"deviceFingerprinting"`
            hashedServerSecret  string `json:"hashedServerSecret"`
            hashedUsername      string `json:"hashedUsername"`
            serverSecret        string `json:"serverSecret"`
            username            string `json:"username"`
        } `json:"fingerprint"`
        negotiatedAuthnContext struct {
            authenticationMethod string `json:"authenticationMethod"`
            displayName          string `json:"displayName"`
        } `json:"negotiatedAuthnContext"`
        requestIp       string `json:"requestIp"`
        requestReceived int    `json:"requestReceived"`
        sessionId       string `json:"sessionId"`
    } `json:"authenticationContext"`
    client struct {
        deviceAgent string `json:"deviceAgent"`
        id          string `json:"id"`
        ipAddress   string `json:"ipAddress"`
        userAgent   string `json:"userAgent"`
    } `json:"client"`
    debugContext struct {
        debugData struct {
            request struct {
                headers struct {
                    accept                 string `json:"Accept"`
                    acceptEncoding         string `json:"Accept-Encoding"`
                    acceptLanguage         string `json:"Accept-Language"`
                    authorization          string `json:"Authorization"`
                    cacheControl           string `json:"Cache-Control"`
                    connection             string `json:"Connection"`
                    host                   string `json:"Host"`
                    ifModifiedSince        string `json:"If-Modified-Since"`
                    origin                 string `json:"Origin"`
                    referer                string `json:"Referer"`
                    secWebSocketExtensions string `json:"Sec-WebSocket-Extensions"`
                    secWebSocketKey        string `json:"Sec-WebSocket-Key"`
                    secWebSocketVersion    string `json:"Sec-WebSocket-Version"`
                    userAgent              string `json:"User-Agent"`
                } `json:"headers"`
                method string `json:"method"`
                path   string `json:"path"`
                query  struct {
                    errorCode string `json:"errorCode"`
                    errorSummary string `json:"errorSummary"`
                    state string `json:"state"`
                } `json:"query"`
                remoteAddr string `json:"remoteAddr"`
                body       string `json:"body"`
            } `json:"request"`
            response struct {
                headers struct {
                    accessControlAllowOrigin string `json:"Access-Control-Allow-Origin"`
                    cacheControl            string `json:"Cache-Control"`