package main

import (
	"bytes"
	"mime/multipart"
	"net/http"
	"net/http/httptest"
	"testing"
)

func TestParseDriverCoordinates(t *testing.T) {
	tests := []struct {
		name      string
		latitude  string
		longitude string
		valid     bool
	}{
		{"valid", "10.776889", "106.700806", true},
		{"missing latitude", "", "106.700806", false},
		{"missing longitude", "10.776889", "", false},
		{"out of range", "91", "106.700806", false},
		{"not a number", "NaN", "106.700806", false},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			_, _, err := parseDriverCoordinates(test.latitude, test.longitude)
			if (err == nil) != test.valid {
				t.Fatalf("valid=%v, error=%v", test.valid, err)
			}
		})
	}
}

func TestRegisterDriverRequiresCoordinates(t *testing.T) {
	var body bytes.Buffer
	writer := multipart.NewWriter(&body)
	for key, value := range map[string]string{
		"user_name":    "driver_without_location",
		"password":     "secret123",
		"phone_number": "0901234567",
		"role":         "DRIVER",
	} {
		if err := writer.WriteField(key, value); err != nil {
			t.Fatal(err)
		}
	}
	if err := writer.Close(); err != nil {
		t.Fatal(err)
	}
	request := httptest.NewRequest(http.MethodPost, "/api/user/register", &body)
	request.Header.Set("Content-Type", writer.FormDataContentType())
	response := httptest.NewRecorder()
	registerUser(response, request)
	if response.Code != http.StatusBadRequest {
		t.Fatalf("status=%d, body=%s", response.Code, response.Body.String())
	}
}
