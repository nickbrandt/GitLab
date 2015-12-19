package main

import (
	"flag"
	"log"
	"net/url"
)

type urlFlag struct{ *url.URL }

func (u *urlFlag) Set(s string) error {
	myURL, err := url.Parse(s)
	if err != nil {
		return err
	}
	u.URL = myURL
	return nil
}

func URLFlag(name string, value string, usage string) *url.URL {
	u, err := url.Parse(value)
	if err != nil {
		log.Fatalf("URLFlag: invalid default: %q %v", value, err)
	}
	f := urlFlag{u}
	flag.CommandLine.Var(&f, name, usage)
	return f.URL
}
