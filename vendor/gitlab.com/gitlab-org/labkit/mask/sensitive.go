package mask

// IsSensitiveParam will return true if the given parameter name should be masked for sensitivity
func IsSensitiveParam(name string) bool {
	return parameterMatcher.MatchString(name)
}

// IsSensitiveHeader will return true if the given parameter name should be masked for sensitivity
func IsSensitiveHeader(name string) bool {
	return headerMatcher.MatchString(name)
}
