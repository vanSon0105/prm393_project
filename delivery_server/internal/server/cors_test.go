package server

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestWebCORS(t *testing.T) {
	handler := withWebCORS(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	}))

	request := httptest.NewRequest(http.MethodOptions, "/api/admin/drivers", nil)
	request.Header.Set("Origin", "http://localhost:63289")
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != http.StatusNoContent {
		t.Fatalf("preflight status = %d", response.Code)
	}
	if got := response.Header().Get("Access-Control-Allow-Origin"); got != "http://localhost:63289" {
		t.Fatalf("allowed origin = %q", got)
	}

	request = httptest.NewRequest(http.MethodOptions, "/api/admin/drivers", nil)
	request.Header.Set("Origin", "https://example.com")
	response = httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	if response.Code != http.StatusForbidden {
		t.Fatalf("unexpected origin status = %d", response.Code)
	}
}
