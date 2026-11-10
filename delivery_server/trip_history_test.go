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

type historyTestDB struct {
	profileRows    [][]driver.Value
	tripRows       [][]driver.Value
	activeTripRows [][]driver.Value
	query          string
	args           []driver.NamedValue
}

type historyDriver struct{ data *historyTestDB }
type historyConn struct{ data *historyTestDB }
type historyRows struct {
	columns []string
	values  [][]driver.Value
	index   int
}

func (d historyDriver) Open(string) (driver.Conn, error) { return historyConn{d.data}, nil }
func (c historyConn) Prepare(string) (driver.Stmt, error) {
	return nil, errors.New("prepared statements are not expected")
}
func (c historyConn) Close() error { return nil }
func (c historyConn) Begin() (driver.Tx, error) {
	return nil, errors.New("transactions are not expected")
}
func (c historyConn) QueryContext(_ context.Context, query string, args []driver.NamedValue) (driver.Rows, error) {
	if strings.Contains(query, "SELECT t.trip_id, t.customer_id, t.trip_distance, t.trip_price") {
		c.data.query = query
		c.data.args = append([]driver.NamedValue(nil), args...)
		return &historyRows{
			columns: []string{"trip_id", "customer_id", "trip_distance", "trip_price",
				"trip_latitude", "trip_longitude", "destination_latitude",
				"destination_longitude", "trip_status_id", "status"},
			values: c.data.activeTripRows,
		}, nil
	}
	if strings.Contains(query, "FROM Profile p") {
		return &historyRows{columns: []string{"role_value"}, values: c.data.profileRows}, nil
	}
	if strings.Contains(query, "FROM Trip t") {
		c.data.query = query
		c.data.args = append([]driver.NamedValue(nil), args...)
		return &historyRows{
			columns: []string{
				"trip_id", "trip_distance", "trip_price", "customer_id", "driver_id",
				"trip_status_id", "status", "trip_latitude", "trip_longitude",
				"destination_latitude", "destination_longitude", "customer_name", "driver_name", "review_vote", "review_comment",
			},
			values: c.data.tripRows,
		}, nil
	}
	return nil, fmt.Errorf("unexpected query: %s", query)
}
func (r *historyRows) Columns() []string { return r.columns }
func (r *historyRows) Close() error      { return nil }
func (r *historyRows) Next(dest []driver.Value) error {
	if r.index >= len(r.values) {
		return io.EOF
	}
	copy(dest, r.values[r.index])
	r.index++
	return nil
}

var historyDriverSequence atomic.Uint64

func useHistoryTestDB(t *testing.T, role string, trips [][]driver.Value) *historyTestDB {
	t.Helper()
	data := &historyTestDB{
		profileRows: [][]driver.Value{{role}},
		tripRows:    trips,
	}
	name := fmt.Sprintf("history-test-%d", historyDriverSequence.Add(1))
	sql.Register(name, historyDriver{data})
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
	return data
}

func requestTripHistory(t *testing.T, path string) (*httptest.ResponseRecorder, map[string]interface{}) {
	t.Helper()
	recorder := httptest.NewRecorder()
	getTripHistoryByProfile(recorder, httptest.NewRequest(http.MethodGet, path, nil))
	var body map[string]interface{}
	if err := json.Unmarshal(recorder.Body.Bytes(), &body); err != nil {
		t.Fatalf("invalid JSON response: %v", err)
	}
	return recorder, body
}

func TestTripHistoryRejectsInvalidParameters(t *testing.T) {
	for _, path := range []string{
		"/api/trips/history",
		"/api/trips/history?profile_id=-1",
		"/api/trips/history?profile_id=7&limit=101",
		"/api/trips/history?profile_id=7&offset=-1",
	} {
		recorder, _ := requestTripHistory(t, path)
		if recorder.Code != http.StatusBadRequest {
			t.Errorf("%s: got %d, want 400", path, recorder.Code)
		}
	}
}

func TestTripHistoryCustomerUsesProfileAndPagination(t *testing.T) {
	data := useHistoryTestDB(t, "CUSTOMER", [][]driver.Value{
		{int64(31), int64(8), float64(42000), int64(7), int64(9), int64(4), "COMPLETED", float64(21.03), float64(105.85), float64(21.04), float64(105.86), "Customer A", "Driver B", int64(5), "Great driver"},
		{int64(30), int64(3), float64(22000), int64(7), nil, int64(5), "CANCEL", float64(21.03), float64(105.85), float64(21.04), float64(105.86), "Customer A", nil, nil, nil},
	})
	recorder, body := requestTripHistory(t, "/api/trips/history?profile_id=7&limit=1&offset=2")
	if recorder.Code != http.StatusOK {
		t.Fatalf("got %d: %s", recorder.Code, recorder.Body.String())
	}
	if !strings.Contains(data.query, "WHERE t.customer_id = ?") {
		t.Fatalf("customer query is not scoped to customer_id: %s", data.query)
	}
	if !strings.Contains(data.query, "t.trip_status_id IN (?, ?)") {
		t.Fatalf("query does not filter terminal trip statuses: %s", data.query)
	}
	wantArgs := []interface{}{int64(7), int64(4), int64(5), int64(2), int64(2)}
	for i, want := range wantArgs {
		if data.args[i].Value != want {
			t.Errorf("arg %d = %v, want %v", i, data.args[i].Value, want)
		}
	}
	items := body["data"].([]interface{})
	if len(items) != 1 || body["has_more"] != true {
		t.Fatalf("unexpected pagination: %v", body)
	}
	trip := items[0].(map[string]interface{})
	if trip["trip_id"] != float64(31) || trip["driver_name"] != "Driver B" {
		t.Fatalf("unexpected trip data: %v", trip)
	}
	if trip["review_vote"] != float64(5) {
		t.Fatalf("review vote not returned: %v", trip)
	}
	if trip["review_comment"] != "Great driver" {
		t.Fatalf("review comment not returned: %v", trip)
	}
}

func TestTripHistoryDriverUsesDriverID(t *testing.T) {
	data := useHistoryTestDB(t, "DRIVER", [][]driver.Value{
		{int64(31), int64(8), float64(42000), int64(7), int64(9), int64(4), "COMPLETED", float64(21.03), float64(105.85), float64(21.04), float64(105.86), "Customer A", "Driver B", int64(4), "Safe ride"},
	})
	recorder, body := requestTripHistory(t, "/api/trips/history?profile_id=9")
	if recorder.Code != http.StatusOK {
		t.Fatalf("got %d: %s", recorder.Code, recorder.Body.String())
	}
	if !strings.Contains(data.query, "WHERE t.driver_id = ?") || data.args[0].Value != int64(9) {
		t.Fatalf("driver query is not scoped to driver_id: %s, %v", data.query, data.args)
	}
	if body["role"] != "DRIVER" || len(body["data"].([]interface{})) != 1 {
		t.Fatalf("unexpected response: %v", body)
	}
	trip := body["data"].([]interface{})[0].(map[string]interface{})
	if trip["review_vote"] != float64(4) || trip["review_comment"] != "Safe ride" {
		t.Fatalf("driver review not returned: %v", trip)
	}
}

func TestTripHistoryRejectsAdminProfile(t *testing.T) {
	useHistoryTestDB(t, "ADMIN", nil)
	recorder, _ := requestTripHistory(t, "/api/trips/history?profile_id=1")
	if recorder.Code != http.StatusForbidden {
		t.Fatalf("got %d, want 403", recorder.Code)
	}
}

func TestTripHistoryReturns404ForMissingProfile(t *testing.T) {
	data := useHistoryTestDB(t, "CUSTOMER", nil)
	data.profileRows = nil
	recorder, _ := requestTripHistory(t, "/api/trips/history?profile_id=999")
	if recorder.Code != http.StatusNotFound {
		t.Fatalf("got %d, want 404", recorder.Code)
	}
}

func TestTripHistoryReturnsEmptyArray(t *testing.T) {
	useHistoryTestDB(t, "CUSTOMER", nil)
	recorder, body := requestTripHistory(t, "/api/trips/history?profile_id=7")
	if recorder.Code != http.StatusOK {
		t.Fatalf("got %d, want 200", recorder.Code)
	}
	items, ok := body["data"].([]interface{})
	if !ok || len(items) != 0 || body["has_more"] != false {
		t.Fatalf("expected empty history array: %v", body)
	}
}

func TestActiveDriverTripRestoresOnlyCurrentDriverTrip(t *testing.T) {
	data := useHistoryTestDB(t, "DRIVER", nil)
	data.activeTripRows = [][]driver.Value{{
		int64(4), int64(3), int64(8), float64(42000),
		float64(21.01565), float64(105.50445),
		float64(21.02322), float64(105.89849), int64(tripStatusGoingV2), "GOING",
	}}
	recorder := httptest.NewRecorder()
	getActiveDriverTripV2(recorder, httptest.NewRequest(
		http.MethodGet, "/api/driver/trips/active?driver_id=6", nil,
	))
	if recorder.Code != http.StatusOK {
		t.Fatalf("got %d: %s", recorder.Code, recorder.Body.String())
	}
	if len(data.args) != 3 || data.args[0].Value != int64(6) ||
		data.args[1].Value != int64(tripStatusAcceptedV2) ||
		data.args[2].Value != int64(tripStatusGoingV2) {
		t.Fatalf("active trip query is not scoped to this driver and active statuses: %v", data.args)
	}
	var body struct {
		Data struct {
			TripID       int `json:"trip_id"`
			DriverID     int `json:"driver_id"`
			TripStatusID int `json:"trip_status_id"`
		} `json:"data"`
	}
	if err := json.Unmarshal(recorder.Body.Bytes(), &body); err != nil {
		t.Fatal(err)
	}
	if body.Data.TripID != 4 || body.Data.DriverID != 6 || body.Data.TripStatusID != tripStatusGoingV2 {
		t.Fatalf("unexpected active trip: %+v", body.Data)
	}
}

func TestActiveDriverTripReturnsNullWhenNoTrip(t *testing.T) {
	useHistoryTestDB(t, "DRIVER", nil)
	recorder := httptest.NewRecorder()
	getActiveDriverTripV2(recorder, httptest.NewRequest(
		http.MethodGet, "/api/driver/trips/active?driver_id=6", nil,
	))
	if recorder.Code != http.StatusOK || !strings.Contains(recorder.Body.String(), `"data":null`) {
		t.Fatalf("expected empty trip response, got %d: %s", recorder.Code, recorder.Body.String())
	}
}
