// Reproduction for git-lfs/lfs-test-server#128: concurrent uploads of the same
// object can fail with HTTP 500 and delete the object's metadata.
//
// Copy this file into a checkout of https://github.com/git-lfs/lfs-test-server
// and run: go test -run TestRepro -v .
// Both tests fail on d27ad23 (latest main as of 2026-09-23).

package main

import (
	"bytes"
	"io"
	"net/http"
	"path/filepath"
	"sync"
	"testing"
	"time"
)

// blockingReader signals when the store starts reading it, then blocks until released,
// so a second upload can be started while the first one is mid-write.
type blockingReader struct {
	started, release chan struct{}
	once             sync.Once
	r                io.Reader
}

func (b *blockingReader) Read(p []byte) (int, error) {
	b.once.Do(func() { close(b.started); <-b.release })
	return b.r.Read(p)
}

func TestReproConcurrentPutSameObject(t *testing.T) {
	setup()
	defer teardown()

	m := &MetaObject{Oid: "6ae8a75555209fd6c44157c0aed8016e763ff435a19cf186f76863140143ff72", Size: 12}
	first := &blockingReader{started: make(chan struct{}), release: make(chan struct{}), r: bytes.NewBufferString("test content")}
	errc := make(chan error, 1)
	go func() { errc <- contentStore.Put(m, first) }()
	<-first.started

	if err := contentStore.Put(m, bytes.NewBufferString("test content")); err != nil {
		t.Errorf("overlapping upload of the same object failed: %v", err)
	}
	close(first.release)
	if err := <-errc; err != nil {
		t.Errorf("first upload failed: %v", err)
	}
}

func TestReproConcurrentHTTPPutDeletesMeta(t *testing.T) {
	// Restore the seeded metadata so a failure here doesn't break later tests.
	t.Cleanup(func() { testMetaStore.Put(&RequestVars{Oid: contentOid, Size: contentSize}) })

	url := lfsServer.URL + "/user/repo/objects/" + contentOid
	put := func(body io.Reader) *http.Response {
		req, _ := http.NewRequest("PUT", url, body)
		req.SetBasicAuth(testUser, testPass)
		req.Header.Set("Accept", contentMediaType)
		req.Header.Set("Content-Type", "application/octet-stream")
		res, err := http.DefaultClient.Do(req)
		if err != nil {
			t.Fatalf("request error: %v", err)
		}
		res.Body.Close()
		return res
	}

	// Upload A: send part of the body, keep the connection open.
	pr, pw := io.Pipe()
	done := make(chan int, 1)
	go func() { done <- put(pr).StatusCode }()
	pw.Write([]byte(content[:2]))
	// Wait until upload A has created its temp file.
	tmpGlob := filepath.Join("lfs-content-test", filepath.Dir(transformKey(contentOid)), "*.tmp")
	for i := 0; i < 200; i++ {
		if m, _ := filepath.Glob(tmpGlob); len(m) > 0 {
			break
		}
		time.Sleep(10 * time.Millisecond)
	}

	// Upload B of the same object while A is in flight.
	if code := put(bytes.NewBufferString(content)).StatusCode; code != 200 {
		t.Errorf("overlapping PUT returned %d, want 200", code)
	}
	pw.Write([]byte(content[2:]))
	pw.Close()
	if code := <-done; code != 200 {
		t.Errorf("first PUT returned %d, want 200", code)
	}

	// The object's metadata must survive.
	res, err := api("GET", "/bilbo/repo/objects/"+contentOid, metaMediaType, testUser, testPass, nil)
	if err != nil {
		t.Fatalf("meta request error: %v", err)
	}
	if res.StatusCode != 200 {
		t.Errorf("after overlapping uploads, GET meta returned %d, want 200 (metadata was deleted)", res.StatusCode)
	}
}
