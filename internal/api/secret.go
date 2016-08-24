package api

import (
	"encoding/base64"
	"fmt"
	"io/ioutil"
	"sync"
)

const numSecretBytes = 32

type Secret struct {
	File  string
	bytes []byte
	sync.RWMutex
}

func (s *Secret) Bytes() ([]byte, error) {
	if bytes := s.getBytes(); bytes != nil {
		return bytes, nil
	}

	return s.setBytes()
}

func (s *Secret) getBytes() []byte {
	s.RLock()
	defer s.RUnlock()
	return s.bytes
}

func (s *Secret) setBytes() ([]byte, error) {
	base64Bytes, err := ioutil.ReadFile(s.File)
	if err != nil {
		return nil, fmt.Errorf("read Secret.File: %v", err)
	}

	secretBytes := make([]byte, base64.StdEncoding.DecodedLen(len(base64Bytes)))
	n, err := base64.StdEncoding.Decode(secretBytes, base64Bytes)
	if err != nil {
		return nil, fmt.Errorf("decode secret: %v", err)
	}

	if n != numSecretBytes {
		return nil, fmt.Errorf("expected %d secretBytes in %s, found %d", numSecretBytes, s.File, n)
	}

	s.Lock()
	defer s.Unlock()
	s.bytes = secretBytes

	return secretBytes, nil
}
