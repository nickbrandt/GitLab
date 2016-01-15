package main

import (
	"flag"
	"net/url"
)

type urlFlag struct {
	*url.URL
}

func (u *urlFlag) Set(s string) error {
	myURL, err := url.Parse(s)
	if err != nil {
		return err
	}
	u.URL = myURL
	return nil
}

func URLFlag(name string, value *url.URL, usage string) **url.URL {
	f := &urlFlag{value}
	flag.CommandLine.Var(f, name, usage)
	return &f.URL
}
