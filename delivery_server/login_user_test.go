package main

import (
	"context"
	"database/sql"
	"database/sql/driver"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"
)

type loginTestDriver struct {
	profiles [][]driver.Value
	active   int64
}

type loginTestConn struct{ data loginTestDriver }

type loginTestRows struct {
	columns []string
	values  [][]driver.Value
	index   int
}

func (d loginTestDriver) Open(string) (driver.Conn, error) { return loginTestConn{d}, nil }
func (c loginTestConn) Prepare(string) (driver.Stmt, error) {
	return nil, errors.New("prepared statements are not expected")
}
func (c loginTestConn) Close() error { return nil }
func (c loginTestConn) Begin() (driver.Tx, error) {
	return nil, errors.New("transactions are not expected")
}
func (c loginTestConn) QueryContext(_ context.Context, query string, _ []driver.NamedValue) (driver.Rows, error) {
	switch {
	case strings.Contains(query, "FROM Profile p"):
		return &loginTestRows{columns: []string{"profile_id", "password", "role_value"}, values: c.data.profiles}, nil
	case strings.Contains(query, "FROM Driver"):
		return &loginTestRows{columns: []string{"active"}, values: [][]driver.Value{{c.data.active}}}, nil
	default:
		return nil, fmt.Errorf("unexpected query: %s", query)
	}
}
func (r *loginTestRows) Columns() []string { return r.columns }
func (r *loginTestRows) Close() error      { return nil }
func (r *loginTestRows) Next(dest []driver.Value) error {
	if r.index >= len(r.values) {
		return io.EOF
	}
	copy(dest, r.values[r.index])
	r.index++
	return nil
}

var loginTestSequence atomic.Uint64

func useLoginTestDB(t *testing.T, profiles [][]driver.Value, active int64) {
	t.Helper()
	name := fmt.Sprintf("login-test-%d", loginTestSequence.Add(1))
	sql.Register(name, loginTestDriver{profiles: profiles, active: active})
	testDB, err := sql.Open(name, "")
	if err != nil {
		t.Fatal(err)
	}
	previousDB := db
	db = testDB
	t.Cleanup(func() {
		db = previousDB
		testDB.Close()
	})
}

func TestLoginUsesStoredRole(t *testing.T) {
	for _, tc := range []struct {
		name string
		role string
	}{
		{name: "customer", role: "CUSTOMER"},
		{name: "driver", role: "DRIVER"},
		{name: "admin", role: "ADMIN"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			useLoginTestDB(t, [][]driver.Value{{int64(7), "secret123", tc.role}}, 1)
			request := httptest.NewRequest(http.MethodPost, "/api/user/login", strings.NewReader(
				`{"user_name":"same_user","password":"secret123","role":"ADMIN"}`,
			))
			response := httptest.NewRecorder()
			loginUser(response, request)
			if response.Code != http.StatusOK {
				t.Fatalf("status = %d, body = %s", response.Code, response.Body.String())
			}
			var body struct {
				Data struct {
					Role   string `json:"role"`
					Status string `json:"status"`
				} `json:"data"`
			}
			if err := json.Unmarshal(response.Body.Bytes(), &body); err != nil {
				t.Fatal(err)
			}
			if body.Data.Role != tc.role || body.Data.Status != "APPROVED" {
				t.Fatalf("got role %q and status %q, want %q and APPROVED", body.Data.Role, body.Data.Status, tc.role)
			}
		})
	}
}

func TestLoginRejectsDuplicateUsername(t *testing.T) {
	useLoginTestDB(t, [][]driver.Value{
		{int64(7), "secret123", "CUSTOMER"},
		{int64(8), "secret123", "ADMIN"},
	}, 1)
	request := httptest.NewRequest(http.MethodPost, "/api/user/login", strings.NewReader(
		`{"user_name":"same_user","password":"secret123"}`,
	))
	response := httptest.NewRecorder()
	loginUser(response, request)
	if response.Code != http.StatusConflict {
		t.Fatalf("status = %d, body = %s", response.Code, response.Body.String())
	}
}
