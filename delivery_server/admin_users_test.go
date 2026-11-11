package main

import (
	"context"
	"database/sql"
	"database/sql/driver"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"sync/atomic"
	"testing"
)

type adminUsersTestDriver struct{ records [][]driver.Value }
type adminUsersTestConn struct{ records [][]driver.Value }

func (d adminUsersTestDriver) Open(string) (driver.Conn, error) {
	return adminUsersTestConn{records: d.records}, nil
}
func (c adminUsersTestConn) Prepare(string) (driver.Stmt, error) {
	return nil, errors.New("prepared statements are not expected")
}
func (c adminUsersTestConn) Close() error { return nil }
func (c adminUsersTestConn) Begin() (driver.Tx, error) {
	return nil, errors.New("transactions are not expected")
}
func (c adminUsersTestConn) QueryContext(_ context.Context, query string, _ []driver.NamedValue) (driver.Rows, error) {
	if !strings.Contains(query, "LEFT JOIN Driver d ON d.driver_id = p.profile_id") {
		return nil, fmt.Errorf("unexpected query: %s", query)
	}
	return &historyRows{
		columns: []string{"profile_id", "full_name", "user_name", "phone_number", "address", "role_value", "driver_id", "license_front", "license_back", "identity_front", "identity_back"},
		values:  c.records,
	}, nil
}

var adminUsersDriverSequence atomic.Uint64

func TestGetAdminUsersReturnsAllRolesWithoutPassword(t *testing.T) {
	records := [][]driver.Value{
		{int64(1), nil, "admin", nil, nil, "ADMIN", nil, nil, nil, nil, nil},
		{int64(2), "Customer One", "customer1", "0901000002", "Ha Noi", "CUSTOMER", nil, nil, nil, nil, nil},
		{int64(3), "Driver One", "driver1", "0901000003", "Ha Noi", "DRIVER", int64(3), "license.jpg", nil, nil, nil},
	}
	name := fmt.Sprintf("admin-users-test-%d", adminUsersDriverSequence.Add(1))
	sql.Register(name, adminUsersTestDriver{records: records})
	testDB, err := sql.Open(name, "")
	if err != nil {
		t.Fatal(err)
	}
	previousDB := db
	db = testDB
	t.Cleanup(func() { db = previousDB; testDB.Close() })

	recorder := httptest.NewRecorder()
	getAdminUsers(recorder, httptest.NewRequest(http.MethodGet, "/api/admin/users", nil))
	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, body = %s", recorder.Code, recorder.Body.String())
	}
	var users []AdminUserResponse
	if err := json.Unmarshal(recorder.Body.Bytes(), &users); err != nil {
		t.Fatal(err)
	}
	if len(users) != 3 || users[0].Role != "ADMIN" || users[1].Role != "CUSTOMER" || users[2].Role != "DRIVER" {
		t.Fatalf("unexpected users: %+v", users)
	}
	if users[0].FullName != "admin" || users[0].Documents != nil || users[2].Documents == nil || !strings.HasSuffix(users[2].Documents.DrivingLicenseFrontURL, "/image/license.jpg") {
		t.Fatalf("unexpected profile details: %+v", users)
	}
	if strings.Contains(recorder.Body.String(), "password") {
		t.Fatal("response exposed a password field")
	}
}
