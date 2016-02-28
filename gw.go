package main

import (
	"flag"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/go-fsnotify/fsnotify"
	log "github.com/sirupsen/logrus"
)

const (
	Create = 1 << iota
	Write
	Remove
	Rename
	Chmod
)

const (
	IgnoreHidden  = true
	IncludeHidden = false
)

var (
	fl      *flag.FlagSet
	debug   bool
	path    string
	event   string
	file    string
	command string
	help    bool
	version bool
)

func init() {
	// path default is current
	p, _ := os.Getwd()

	fl = flag.NewFlagSet(os.Args[0], flag.ContinueOnError)
	fl.BoolVar(&version, "version", false, "print version")
	fl.BoolVar(&debug, "debug", false, "Enable debug output")
	fl.StringVar(&event, "event", "WRITE", "watch event [CREATE, WRITE, REMOVE, RENAME, CHMOD]")
	fl.StringVar(&path, "path", p, "watch directory path")
	fl.StringVar(&file, "file", "go", "watch file extension")
	fl.StringVar(&command, "command", "", "Execute command after event flag")
}

func main() {
	// Parse commandline flag
	if err := fl.Parse(os.Args[1:]); err != nil {
		os.Exit(1)
	}

	// Show version
	if version {
		fmt.Printf("%s version %s (%s)\n", os.Args[0], Version, GitCommit)
		os.Exit(0)
	}

	// split command flag
	cmd := strings.Split(command, " ")

	// Initial fsnotify watcher
	watcher, err := fsnotify.NewWatcher()
	if err != nil {
		log.Fatal(err)
	}
	defer watcher.Close()

	// make
	done := make(chan bool, 1)

	go func() {
		for {
			select {
			case notify := <-watcher.Events:
				ev := strings.Split(notify.String(), ": ")
				if debug {
					log.Infoln("file:", ev[0], "event:", ev[1], notify.Op)
				}
				c := exec.Command(cmd[0])
				c.Args = cmd[0:]
				c.Stdout = os.Stdout
				c.Stderr = os.Stderr

				f := strings.Split(notify.Name, ".")
				if StringInSlice(f[len(f)-1], strings.Split(file, ",")) {
					if ev[1] == event {
						log.Infoln("modified file:", notify.Name)
						go c.Run()
					}
				}

			case err := <-watcher.Errors:
				log.Errorln("error:", err)
			}
		}
	}()

	d, err := filepath.Abs(path)
	if err != nil {
		log.Fatal(err)
	}

	err = filepath.Walk(d, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil
		}
		if info.IsDir() {
			if IsHidden(info.Name()) && IgnoreHidden {
				return filepath.SkipDir
			}
			err = watcher.Add(path)
			if err != nil {
				log.Fatal(err)
			}
		}
		return nil
	})

	<-done
}

func StringInSlice(str string, list []string) bool {
	for _, v := range list {
		if v == str {
			return true
		}
	}
	return false
}

func IsHidden(d string) bool {
	if d[:1] == "." {
		return true
	}
	return false
}
