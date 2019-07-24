/*
Package mask offers the functionality for non-reversible masking
of sensitive data in the GitLab application.

It provides the ability to determine whether or not a URL parameter or
Header should be considered sensitive.

Additionally, it provides masking functionality to mask sensitive
information that gets logged via logging, structured logging, sentry
and distributed tracing.
*/
package mask
