package log

// AccessLogField is used to select which fields are recorded in the access log. See WithoutFields.
type AccessLogField uint16

const (
	// CorrelationID field will record the Correlation-ID in the access log.
	CorrelationID AccessLogField = 1 << iota

	// HTTPHost field will record the Host Header in the access log.
	HTTPHost

	// HTTPRemoteIP field will record the remote caller in the access log, taking Real-IP and X-Forwarded-For headers into account.
	HTTPRemoteIP

	// HTTPRemoteAddr field will record the remote socket endpoint in the access log.
	HTTPRemoteAddr

	// HTTPRequestMethod field will record the HTTP method in the access log.
	HTTPRequestMethod

	// HTTPURI field will record the URI, including parameters.
	HTTPURI

	// HTTPProto field will record the protocol used to make the request in the access log.
	HTTPProto

	// HTTPResponseStatusCode field will record the response HTTP status code in the access log.
	HTTPResponseStatusCode

	// HTTPResponseSize field will record the response size, in bytes, in the access log.
	HTTPResponseSize

	// HTTPRequestReferrer field will record the referer header in the access log.
	HTTPRequestReferrer

	// HTTPUserAgent field will record the useragent header in the access log.
	HTTPUserAgent

	// RequestDuration field will record the request duration in the access log.
	RequestDuration

	// System field will record the system for the log entry.
	System
)

const defaultEnabledFields = ^AccessLogField(0) // By default, all fields are enabled

// For field definitions, consult the Elastic Common Schema field reference
// https://www.elastic.co/guide/en/ecs/current/ecs-field-reference.html.
const (
	httpHostField               = "host"          // ESC: url.domain
	httpRemoteIPField           = "remote_ip"     // ESC: client.ip
	httpRemoteAddrField         = "remote_addr"   // ESC: client.address
	httpRequestMethodField      = "method"        // ESC: http.request.method
	httpURIField                = "uri"           // ESC url.path + `?` + url.query
	httpProtoField              = "proto"         // ESC: url.scheme
	httpResponseStatusCodeField = "status"        // ESC: http.response.status_code
	httpResponseSizeField       = "written_bytes" // ESC: http.response.body.bytes
	httpRequestReferrerField    = "referrer"      // ESC: http.request.referrer
	httpUserAgentField          = "user_agent"    // ESC: user_agent.original
	requestDurationField        = "duration_ms"   // ESC: no mapping
	systemField                 = "system"        // ESC: no mapping
)
