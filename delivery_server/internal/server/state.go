package server

import (
	"database/sql"
	"fmt"
	"github.com/gorilla/websocket"
	"net"
	"net/http"
	"os"
	"strings"
	"sync"
)

var registerMutex sync.Mutex
var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true
	},
}

type LocationUpdate struct {
	DriverID  int     `json:"driver_id"`
	TripID    int     `json:"trip_id"`
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

type TrackerHub struct {
	sync.Mutex
	Customers map[int][]*websocket.Conn
}

var hub = TrackerHub{
	Customers: make(map[int][]*websocket.Conn),
}

type DriverResponse struct {
	DriverID               int    `json:"driver_id"`
	FullName               string `json:"full_name"`
	PhoneNumber            string `json:"phone_number"`
	Address                string `json:"address"`
	AvatarUrl              string `json:"avatar_url"`
	DrivingLicenseFrontUrl string `json:"driving_license_front_url"`
	DrivingLicenseBackUrl  string `json:"driving_license_back_url"`
	IdentityCardFrontUrl   string `json:"identity_card_front_url"`
	IdentityCardBackUrl    string `json:"identity_card_back_url"`
}

type Trip struct {
	TripID       int     `json:"trip_id"`
	TripDistance int     `json:"trip_distance"`
	TripPrice    float64 `json:"trip_price"`
	CustomerID   int     `json:"customer_id"`
	DriverID     *int    `json:"driver_id"`
	TripStatusID int     `json:"trip_status_id"`
}

type Review struct {
	ReviewID int    `json:"review_id"`
	Comment  string `json:"comment"`
	Vote     int    `json:"vote"`
	DriverID int    `json:"driver_id"`
}

type Role struct {
	RoleId    int    `json:"row_id"`
	RoleValue string `json:"rown_value"`
	RoleState bool   `json:"role_state"`
}

var db *sql.DB

func getLocalIP() string {
	addrs, err := net.InterfaceAddrs()
	if err != nil {
		return "127.0.0.1"
	}
	for _, address := range addrs {
		if ipnet, ok := address.(*net.IPNet); ok && !ipnet.IP.IsLoopback() {
			if ipnet.IP.To4() != nil {
				return ipnet.IP.String()
			}
		}
	}
	return "127.0.0.1"
}

func getPublicBaseURL() string {
	if value := strings.TrimRight(os.Getenv("PUBLIC_BASE_URL"), "/"); value != "" {
		return value
	}
	return fmt.Sprintf("http://%s:8080", getLocalIP())
}

func parseNullString(ns sql.NullString) string {
	if !ns.Valid || ns.String == "" {
		return ""
	}
	return ns.String
}
