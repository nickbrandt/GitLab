package api

import (
	"fmt"
	"io/ioutil"
	"sync"
)

const numSecretBytes = 64

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
	bytes, err := ioutil.ReadFile(s.File)
	if err != nil {
		return nil, fmt.Errorf("read Secret.File: %v", err)
	}
	if n := len(bytes); n != numSecretBytes {
		return nil, fmt.Errorf("expected %d bytes in %s, found %d", bytes, s.File, n)
	}

	s.Lock()
	defer s.Unlock()
	s.bytes = bytes

	return bytes, nil
}
