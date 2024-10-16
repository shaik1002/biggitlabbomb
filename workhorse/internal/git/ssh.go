/*
In this file we handle the Git over SSH GitLab-Shell requests
*/

// Package git handles git operations
package git

import (
	"fmt"
	"net/http"

	"gitlab.com/gitlab-org/gitaly/v16/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitaly/v16/client"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
)

type flushWriter struct {
	http.ResponseWriter
	controller *http.ResponseController
}

func (f *flushWriter) Write(p []byte) (int, error) {
	n, err := f.ResponseWriter.Write(p)
	if err != nil {
		return n, err
	}

	return n, f.controller.Flush()
}

// SSHUploadPack handles git pull SSH connection between GitLab-Shell and Gitaly through Workhorse
func SSHUploadPack(a *api.API) http.Handler {
	return repoPreAuthorizeHandler(a, handleSSHUploadPack)
}

func handleSSHUploadPack(w http.ResponseWriter, r *http.Request, a *api.Response) {
	controller := http.NewResponseController(w) //nolint:bodyclose // false-positive https://github.com/timakin/bodyclose/issues/52
	if err := controller.EnableFullDuplex(); err != nil {
		fail.Request(w, r, fmt.Errorf("enabling full duplex: %v", err))
		return
	}

	conn, registry, err := gitaly.NewConnectionWithSidechannel(a.GitalyServer)
	if err != nil {
		fail.Request(w, r, fmt.Errorf("look up for gitaly connection: %v", err))
		return
	}

	w.WriteHeader(http.StatusOK)

	request := &gitalypb.SSHUploadPackWithSidechannelRequest{
		Repository:       &a.Repository,
		GitProtocol:      r.Header.Get("Git-Protocol"),
		GitConfigOptions: a.GitConfigOptions,
	}
	out := &flushWriter{ResponseWriter: w, controller: controller}
	_, err = client.UploadPackWithSidechannelWithResult(r.Context(), conn, registry, r.Body, out, out, request)
	if err != nil {
		fail.Request(w, r, fmt.Errorf("upload pack failed: %v", err))
		return
	}
}
